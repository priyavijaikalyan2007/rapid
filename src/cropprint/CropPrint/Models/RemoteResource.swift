import Combine
import CoreText
import Foundation

enum RemoteResourceKind: String, Codable, CaseIterable {
    case font
    case frame

    var title: String {
        switch self {
        case .font: "Font"
        case .frame: "Frame"
        }
    }
}

struct RemoteResource: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let kind: RemoteResourceKind
    let creator: String
    let sourceURL: URL
    let downloadURL: URL
    let licenseName: String
    let licenseURL: URL
    let notes: String?
    let fontName: String?
}

struct RemoteResourceCatalog: Codable {
    let version: Int
    let resources: [RemoteResource]
}

@MainActor
final class ResourceLibrary: ObservableObject {
    @Published private(set) var resources: [RemoteResource]
    @Published private(set) var status = "The built-in catalog is ready."
    @Published private(set) var activeDownloads = Set<String>()
    @Published var catalogURLString: String {
        didSet { defaults.set(catalogURLString, forKey: Self.catalogURLKey) }
    }

    static let shared = ResourceLibrary()

    private static let catalogURLKey = "remoteResourceCatalogURL"
    private let defaults: UserDefaults
    private let fileManager: FileManager

    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default) {
        self.defaults = defaults
        self.fileManager = fileManager
        catalogURLString = defaults.string(forKey: Self.catalogURLKey) ?? ""
        resources = Self.starterResources
        registerCachedFonts()
    }

    func refreshCatalog() async {
        let value = catalogURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            resources = Self.starterResources
            status = "The built-in catalog is ready."
            return
        }

        guard let url = URL(string: value), url.scheme == "https" else {
            status = "Enter a valid HTTPS catalog address."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validateResponse(response, dataSize: data.count, maximumSize: 1_000_000)
            let catalog = try JSONDecoder().decode(RemoteResourceCatalog.self, from: data)
            try validate(catalog)
            resources = catalog.resources
            status = "Loaded \(catalog.resources.count) licensed resources."
            registerCachedFonts()
        } catch {
            status = "The catalog could not load: \(error.localizedDescription)"
        }
    }

    func download(_ resource: RemoteResource) async {
        guard !activeDownloads.contains(resource.id) else { return }
        activeDownloads.insert(resource.id)
        defer { activeDownloads.remove(resource.id) }

        do {
            try validate(resource)
            let (data, response) = try await URLSession.shared.data(from: resource.downloadURL)
            try validateResponse(response, dataSize: data.count, maximumSize: 25_000_000)
            let destination = try cachedURL(for: resource)
            try data.write(to: destination, options: .atomic)

            if resource.kind == .font {
                try registerFont(at: destination)
            }

            status = "Downloaded \(resource.name)."
            objectWillChange.send()
        } catch {
            status = "\(resource.name) could not download: \(error.localizedDescription)"
        }
    }

    func isDownloaded(_ resource: RemoteResource) -> Bool {
        guard let url = try? cachedURL(for: resource) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    func cachedFileURL(for resourceID: String) -> URL? {
        guard let resource = resources.first(where: { $0.id == resourceID }), isDownloaded(resource) else {
            return nil
        }
        return try? cachedURL(for: resource)
    }

    var availableFonts: [(name: String, fontName: String)] {
        resources
            .filter { $0.kind == .font && isDownloaded($0) }
            .compactMap { resource in
                guard let fontName = resource.fontName else { return nil }
                return (resource.name, fontName)
            }
    }

    var availableFrames: [RemoteResource] {
        resources.filter { $0.kind == .frame && isDownloaded($0) }
    }

    private func registerCachedFonts() {
        for resource in resources where resource.kind == .font && isDownloaded(resource) {
            guard let url = try? cachedURL(for: resource) else { continue }
            try? registerFont(at: url)
        }
    }

    private func registerFont(at url: URL) throws {
        var registrationError: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError)
        if !registered, let error = registrationError?.takeRetainedValue() {
            let code = CFErrorGetCode(error)
            if code != CTFontManagerError.alreadyRegistered.rawValue {
                throw error
            }
        }
    }

    private func cachedURL(for resource: RemoteResource) throws -> URL {
        let folder = try cacheDirectory()
        let fileExtension = resource.downloadURL.pathExtension.lowercased()
        return folder.appendingPathComponent("\(resource.id).\(fileExtension)")
    }

    private func cacheDirectory() throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let folder = root.appendingPathComponent("CropPrint/RemoteResources", isDirectory: true)
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func validate(_ catalog: RemoteResourceCatalog) throws {
        guard catalog.version == 1 else { throw ResourceError.unsupportedCatalog }
        guard !catalog.resources.isEmpty else { throw ResourceError.emptyCatalog }
        guard Set(catalog.resources.map(\.id)).count == catalog.resources.count else {
            throw ResourceError.duplicateIdentifier
        }
        try catalog.resources.forEach(validate)
    }

    private func validate(_ resource: RemoteResource) throws {
        let allowedLicenses = ["OFL-1.1", "Apache-2.0", "Ubuntu-font-1.0", "CC0-1.0", "CC-BY-4.0", "CC-BY-SA-4.0", "MIT"]
        guard allowedLicenses.contains(resource.licenseName) else { throw ResourceError.disallowedLicense }
        guard !resource.name.isEmpty, !resource.creator.isEmpty else { throw ResourceError.missingAttribution }
        guard resource.sourceURL.scheme == "https", resource.downloadURL.scheme == "https", resource.licenseURL.scheme == "https" else {
            throw ResourceError.insecureAddress
        }
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
        guard !resource.id.isEmpty, resource.id.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            throw ResourceError.invalidIdentifier
        }
        let fileExtension = resource.downloadURL.pathExtension.lowercased()
        let allowedExtensions = resource.kind == .font ? ["ttf", "otf"] : ["png", "jpg", "jpeg", "heic", "tiff"]
        guard allowedExtensions.contains(fileExtension) else { throw ResourceError.unsupportedFile }
        if resource.kind == .font, resource.fontName?.isEmpty != false {
            throw ResourceError.missingFontName
        }
    }

    private func validateResponse(_ response: URLResponse, dataSize: Int, maximumSize: Int) throws {
        guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
            throw ResourceError.badResponse
        }
        guard dataSize <= maximumSize else { throw ResourceError.fileTooLarge }
    }

    private static let starterResources: [RemoteResource] = [
        RemoteResource(
            id: "font-pacifico-regular",
            name: "Pacifico",
            kind: .font,
            creator: "Vernon Adams, Jacques Le Bailly, Botjo Nikoltchev, and Ani Petrova",
            sourceURL: URL(string: "https://github.com/google/fonts/tree/main/ofl/pacifico")!,
            downloadURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/pacifico/Pacifico-Regular.ttf")!,
            licenseName: "OFL-1.1",
            licenseURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/pacifico/OFL.txt")!,
            notes: "Downloaded from the official Google Fonts repository.",
            fontName: "Pacifico-Regular"
        ),
        RemoteResource(
            id: "font-bungee-regular",
            name: "Bungee",
            kind: .font,
            creator: "David Jonathan Ross",
            sourceURL: URL(string: "https://github.com/google/fonts/tree/main/ofl/bungee")!,
            downloadURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/Bungee-Regular.ttf")!,
            licenseName: "OFL-1.1",
            licenseURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/OFL.txt")!,
            notes: "Downloaded from the official Google Fonts repository.",
            fontName: "Bungee-Regular"
        ),
        RemoteResource(
            id: "font-libre-baskerville",
            name: "Libre Baskerville",
            kind: .font,
            creator: "Impallari Type",
            sourceURL: URL(string: "https://github.com/google/fonts/tree/main/ofl/librebaskerville")!,
            downloadURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/librebaskerville/LibreBaskerville%5Bwght%5D.ttf")!,
            licenseName: "OFL-1.1",
            licenseURL: URL(string: "https://raw.githubusercontent.com/google/fonts/main/ofl/librebaskerville/OFL.txt")!,
            notes: "Downloaded from the official Google Fonts repository.",
            fontName: "LibreBaskerville-Regular"
        )
    ]
}

private enum ResourceError: LocalizedError {
    case unsupportedCatalog
    case emptyCatalog
    case duplicateIdentifier
    case disallowedLicense
    case missingAttribution
    case insecureAddress
    case invalidIdentifier
    case unsupportedFile
    case badResponse
    case fileTooLarge
    case missingFontName

    var errorDescription: String? {
        switch self {
        case .unsupportedCatalog: "The catalog version is not supported."
        case .emptyCatalog: "The catalog contains no resources."
        case .duplicateIdentifier: "The catalog contains duplicate identifiers."
        case .disallowedLicense: "The resource license is not allowed."
        case .missingAttribution: "The resource attribution is incomplete."
        case .insecureAddress: "All resource addresses must use HTTPS."
        case .invalidIdentifier: "A resource identifier contains unsupported characters."
        case .unsupportedFile: "The resource file type is not supported."
        case .badResponse: "The server returned an invalid response."
        case .fileTooLarge: "The downloaded file is too large."
        case .missingFontName: "A font entry does not contain its PostScript font name."
        }
    }
}
