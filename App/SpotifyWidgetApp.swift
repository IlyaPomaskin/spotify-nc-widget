import AppKit
import NowPlayingKit
import ServiceManagement
import SwiftUI

@main
struct SpotifyWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: NowPlayingMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerLoginItem()

        guard let store = AppGroup.store() else {
            NSLog("SpotifyWidget: App Group container unavailable, check AppGroupID and entitlements")
            return
        }
        let monitor = NowPlayingMonitor(
            controller: SpotifyController(),
            store: store,
            artwork: ArtworkCache(store: store)
        )
        monitor.start()
        self.monitor = monitor
    }

    private func registerLoginItem() {
        guard SMAppService.mainApp.status != .enabled else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            NSLog("SpotifyWidget: login item registration failed: \(error)")
        }
    }
}
