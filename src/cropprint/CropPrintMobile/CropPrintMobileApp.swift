import SwiftUI

@main
struct CropPrintMobileApp: App {
    @StateObject private var resourceLibrary = ResourceLibrary.shared

    var body: some Scene {
        WindowGroup {
            MobileContentView()
                .environmentObject(resourceLibrary)
        }
    }
}
