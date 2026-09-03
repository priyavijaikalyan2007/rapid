import SwiftUI

@main
struct CropPrintApp: App {
    @StateObject private var document = PhotoDocument()
    @StateObject private var resourceLibrary = ResourceLibrary.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(document)
                .environmentObject(resourceLibrary)
                .frame(minWidth: 1180, minHeight: 680)
                .onOpenURL { url in
                    document.open(url: url)
                }
        }
        .commands {
            InformationCommands()

            CommandGroup(replacing: .newItem) {
                Button("Open Photo…") {
                    document.showOpenPanel()
                }
                .keyboardShortcut("o")

                Menu("Open Recent") {
                    if document.recentPhotoURLs.isEmpty {
                        Text("No Recent Photos")
                    } else {
                        ForEach(document.recentPhotoURLs, id: \.self) { url in
                            Button(url.lastPathComponent) {
                                document.open(url: url)
                            }
                            .help(url.path)
                        }

                        Divider()

                        Button("Clear Menu") {
                            document.clearRecentPhotos()
                        }
                    }
                }
            }

            CommandGroup(after: .saveItem) {
                Button("Crop and Save") {
                    document.cropAndSave()
                }
                .keyboardShortcut("s")
                .disabled(!document.canExport)

                Button("Create Print Sheet…") {
                    document.showPrintSheetPanel()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!document.canCreatePrintSheet)
            }
        }

        Window("About CropPrint", id: "about-cropprint") {
            AboutCropPrintView()
                .environmentObject(resourceLibrary)
        }

        Window("Attributions", id: "attributions") {
            AttributionsView()
                .environmentObject(resourceLibrary)
        }

        Window("Remote Resources", id: "remote-resources") {
            ResourceLibraryView()
                .environmentObject(resourceLibrary)
        }

        Window("CropPrint Help", id: "cropprint-help") {
            CropPrintHelpView()
        }

    }
}

private struct InformationCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About CropPrint") {
                openWindow(id: "about-cropprint")
            }

            Button("Attributions…") {
                openWindow(id: "attributions")
            }

            Button("Remote Resources…") {
                openWindow(id: "remote-resources")
            }
        }

        CommandGroup(replacing: .help) {
            Button("CropPrint Help") {
                openWindow(id: "cropprint-help")
            }
            .keyboardShortcut("?", modifiers: .command)

            Link(destination: URL(string: "https://github.com/priyavijaikalyan2007/rapid/issues/new/choose")!) {
                Text("Report an Issue…")
            }
        }
    }
}
