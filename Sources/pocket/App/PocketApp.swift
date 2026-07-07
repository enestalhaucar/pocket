import SwiftUI

@main
struct PocketApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        MenuBarExtra {
            RootView()
                .environmentObject(store)
        } label: {
            Image(systemName: "tray.full.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
