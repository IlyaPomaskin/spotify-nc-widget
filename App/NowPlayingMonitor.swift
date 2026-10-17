import AppKit
import NowPlayingKit
import WidgetKit

@MainActor
final class NowPlayingMonitor: NSObject {
    private static let spotifyStateChanged = Notification.Name("com.spotify.client.PlaybackStateChanged")
    private static let debounceInterval: Duration = .milliseconds(100)

    private let controller: SpotifyController
    private let store: NowPlayingStore
    private let artwork: ArtworkCache
    private var pendingRefresh: Task<Void, Never>?

    init(controller: SpotifyController, store: NowPlayingStore, artwork: ArtworkCache) {
        self.controller = controller
        self.store = store
        self.artwork = artwork
    }

    func start() {
        let distributedCenter = DistributedNotificationCenter.default()
        distributedCenter.addObserver(
            self,
            selector: #selector(spotifyStateDidChange),
            name: Self.spotifyStateChanged,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        PlayerCommand.allCases.forEach { command in
            distributedCenter.addObserver(
                self,
                selector: #selector(commandReceived(_:)),
                name: command.notificationName,
                object: nil,
                suspensionBehavior: .deliverImmediately
            )
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        [NSWorkspace.didLaunchApplicationNotification, NSWorkspace.didTerminateApplicationNotification].forEach { name in
            workspaceCenter.addObserver(self, selector: #selector(applicationLifecycleChanged(_:)), name: name, object: nil)
        }

        saveSpotifyIcon()
        scheduleRefresh()
    }

    private func saveSpotifyIcon() {
        guard let data = controller.iconPNGData() else { return }
        do {
            try store.saveSpotifyIcon(data)
        } catch {
            NSLog("SpotifyWidget: saving Spotify icon failed: \(error)")
        }
    }

    @objc private func spotifyStateDidChange() {
        scheduleRefresh()
    }

    @objc private func commandReceived(_ notification: Notification) {
        guard let command = PlayerCommand(notificationName: notification.name) else { return }
        controller.perform(command)
    }

    @objc private func applicationLifecycleChanged(_ notification: Notification) {
        let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        guard application?.bundleIdentifier == SpotifyController.bundleIdentifier else { return }
        scheduleRefresh()
    }

    private func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { [weak self] in
            try? await Task.sleep(for: Self.debounceInterval)
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    private func refresh() async {
        let current = controller.fetch()
        if let current {
            await artwork.ensureArtwork(for: current)
        }
        guard hasChanged(from: store.load(), to: current) else { return }

        do {
            try store.save(current)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            NSLog("SpotifyWidget: saving state failed: \(error)")
        }
    }

    private func hasChanged(from previous: NowPlaying?, to current: NowPlaying?) -> Bool {
        guard let previous, let current else { return (previous == nil) != (current == nil) }
        return !previous.isEquivalent(to: current)
    }
}
