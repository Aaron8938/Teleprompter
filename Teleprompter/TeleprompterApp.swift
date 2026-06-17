import SwiftUI

@main
struct TeleprompterApp: App {
    #if os(macOS)
    init() {
        AppIconProvider.applyApplicationIcon()
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 500, height: 600)
        #endif
    }
}
