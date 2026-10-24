// SPDX-FileCopyrightText: 2026 Vijai Kalyan
// SPDX-FileCopyrightText: 2026 Outcrop Inc
// SPDX-License-Identifier: GPL-3.0-or-later
// Repository: rapid
// File GUID: 7de5cd91-a1c4-4caf-962d-778445e46606
// Created: 2026
// COMPONENT: ResourceLibrary
// PURPOSE: Coordinates licensed resource downloads and the local cache.
// RELATES: [[CropPrint]]
// FLOW: Native application -> ResourceLibrary -> local result.

import Combine
import CoreText
import Foundation
import OSLog

/// Coordinates licensed resource downloads and the local cache.
@MainActor
final class ResourceLibrary: ObservableObject
{
    /// Writes local operation outcomes without including private content or file paths.
    private static let logger = Logger(subsystem: "us.outcrop.apps.cropprint", category: "ResourceLibrary")

    /// User-selected catalog address stored in local preferences.
    @Published private(set) var resources: [RemoteResource]
    @Published private(set) var status = "The built-in catalog is ready."
    @Published private(set) var activeDownloads = Set<String>()
    @Published var catalogURLString: String
    {
        didSet { defaults.set(catalogURLString, forKey: Self.catalogURLKey) }
    }

    /// Shared shared metadata used by ResourceLibrary.
    static let shared = ResourceLibrary()

    /// Prevents repeated refresh taps from retaining several catalog transfers.
    private var catalogIsLoading = false
    /// The catalog urlkey value supplied to this ResourceLibrary instance.
    /// Bounds memory retained by optional downloads started from separate UI actions.
    private static let maximumConcurrentDownloads = 4
    private static let catalogURLKey = "remoteResourceCatalogURL"
    /// The defaults value supplied to this ResourceLibrary instance.
    private let defaults: UserDefaults
    /// The file manager value supplied to this ResourceLibrary instance.
    private let fileManager: FileManager

    /// Restores local preferences and registers already cached fonts for this process.
    init(defaults: UserDefaults = .standard, fileManager: FileManager = .default)
    {
        self.defaults = defaults
        self.fileManager = fileManager
        catalogURLString = defaults.string(forKey: Self.catalogURLKey) ?? ""
        resources = Self.starterResources
        registerCachedFonts()
    }

    /// Serializes explicit catalog refresh requests and preserves the last usable catalog.
    func refreshCatalog() async
    {
        guard !catalogIsLoading
        else
        {
            return
        }
        catalogIsLoading = true
        defer { catalogIsLoading = false }
        await loadCatalog()
    }

    /// Loads one validated catalog while preserving the last usable catalog on failure.
    private func loadCatalog() async
    {
        let value = catalogURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty
        else
        {
            resources = Self.starterResources
            status = "The built-in catalog is ready."
            return
        }

        guard let url = URL(string: value)
        else
        {
            status = "Enter a valid HTTPS catalog address."
            return
        }

        do
        {
            let catalog = try await validatedCatalog(from: url)
            resources = catalog.resources
            Self.logger.info("A validated resource catalog loaded.")
            status = "Loaded \(catalog.resources.count) licensed resources."
            registerCachedFonts()
        }
        catch
        {
            Self.logger.error("The optional catalog refresh failed.")
            status = "The catalog could not load: \(error.localizedDescription)"
        }
    }

    /// Validates and caches one explicitly requested licensed resource within download limits.
    func download(_ resource: RemoteResource) async
    {
        guard activeDownloads.count < Self.maximumConcurrentDownloads, !activeDownloads.contains(resource.id)
        else
        {
            return
        }
        activeDownloads.insert(resource.id)
        defer { activeDownloads.remove(resource.id) }

        do
        {
            try await cacheResource(resource)
            Self.logger.info("A licensed resource download completed.")
            status = "Downloaded \(resource.name)."
            objectWillChange.send()
        }
        catch
        {
            Self.logger.error("The optional resource download failed.")
            status = "\(resource.name) could not download: \(error.localizedDescription)"
        }
    }

    /// Checks whether the validated catalog resource has a cached file.
    func isDownloaded(_ resource: RemoteResource) -> Bool
    {
        guard let url = try? cachedURL(for: resource)
        else
        {
            return false
        }
        return fileManager.fileExists(atPath: url.path)
    }

    /// Resolves only known catalog identifiers to existing local cache files.
    func cachedFileURL(for resourceID: String) -> URL?
    {
        guard let resource = resources.first(where: {
            $0.id == resourceID
        }), isDownloaded(resource) else
        {
            return nil
        }
        return try? cachedURL(for: resource)
    }

    /// Available fonts used by ResourceLibrary.
    var availableFonts: [(name: String, fontName: String)]
    {
        resources
            .filter
            {
                $0.kind == .font && isDownloaded($0)
            }
            .compactMap
            { resource in
                guard let fontName = resource.fontName
                else
                {
                    return nil
                }
                return (resource.name, fontName)
            }
    }

    /// Available frames used by ResourceLibrary.
    var availableFrames: [RemoteResource]
    {
        resources.filter
        {
            $0.kind == .frame && isDownloaded($0)
        }
    }

    /// Registers cached catalog fonts for this application process only.
    private func registerCachedFonts()
    {
        for resource in resources where resource.kind == .font && isDownloaded(resource)
        {
            guard let url = try? cachedURL(for: resource)
            else
            {
                continue
            }
            try? registerFont(at: url)
        }
    }

    /// Registers a font locally and tolerates an already registered font.
    private func registerFont(at url: URL) throws
    {
        var registrationError: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError)
        if !registered, let error = registrationError?.takeRetainedValue()
        {
            let code = CFErrorGetCode(error)
            if code != CTFontManagerError.alreadyRegistered.rawValue
            {
                throw error
            }
        }
    }

    /// Builds a cache path from a validated identifier and supported file extension.
    private func cachedURL(for resource: RemoteResource) throws -> URL
    {
        try ResourceCatalogPolicy.validate(resource)
        let folder = try cacheDirectory()
        let fileExtension = resource.downloadURL.pathExtension.lowercased()
        return folder.appendingPathComponent("\(resource.id).\(fileExtension)")
    }

    /// Creates the application-owned resource folder under local Application Support.
    private func cacheDirectory() throws -> URL
    {
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

    /// Shared starter resources metadata used by ResourceLibrary.
    private static let starterResources: [RemoteResource] = [
        RemoteResource(
            id: "font-pacifico-regular",
            name: "Pacifico",
            kind: .font,
            creator: "Vernon Adams, Jacques Le Bailly, Botjo Nikoltchev, and Ani Petrova",
            sourceURL: URL(string: "https://github.com/google/fonts/tree/main/ofl/pacifico")!,
            downloadURL: URL(
                string: "https://raw.githubusercontent.com/google/fonts/main/ofl/pacifico/Pacifico-Regular.ttf"
            )!,
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
            downloadURL: URL(
                string: "https://raw.githubusercontent.com/google/fonts/main/ofl/bungee/Bungee-Regular.ttf"
            )!,
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
            downloadURL: URL(
                string: "https://raw.githubusercontent.com/google/fonts/main/ofl/librebaskerville/LibreBaskerville%5Bwght%5D.ttf"
            )!,
            licenseName: "OFL-1.1",
            licenseURL: URL(
                string: "https://raw.githubusercontent.com/google/fonts/main/ofl/librebaskerville/OFL.txt"
            )!,
            notes: "Downloaded from the official Google Fonts repository.",
            fontName: "LibreBaskerville-Regular"
        )
    ]

    /// Retrieves bounded JSON and validates every entry before changing the visible catalog.
    private func validatedCatalog(from url: URL) async throws -> RemoteResourceCatalog
    {
        let data = try await BoundedResourceDownloader().data(
            from: url, maximumBytes: ResourceDownloadPolicy.maximumCatalogBytes
        )
        let catalog = try JSONDecoder().decode(RemoteResourceCatalog.self, from: data)
        try ResourceCatalogPolicy.validate(catalog)
        return catalog
    }

    /// Checks transport and file metadata before publishing a resource inside the application cache.
    private func cacheResource(_ resource: RemoteResource) async throws
    {
        try ResourceCatalogPolicy.validate(resource)
        let data = try await BoundedResourceDownloader().data(
            from: resource.downloadURL, maximumBytes: ResourceDownloadPolicy.maximumResourceBytes
        )
        if resource.kind == .frame
        {
            try ImageInputLimits.validate(data: data)
        }
        let destination = try cachedURL(for: resource)
        try data.write(to: destination, options: .atomic)

        if resource.kind == .font
        {
            try registerFont(at: destination)
        }
    }
}
