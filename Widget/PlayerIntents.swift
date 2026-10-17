import AppIntents
import NowPlayingKit

struct PreviousTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Previous Track"

    func perform() async throws -> some IntentResult {
        PlayerCommand.previous.post()
        return .result()
    }
}

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Play or Pause"

    func perform() async throws -> some IntentResult {
        PlayerCommand.playPause.post()
        saveOptimisticToggle()
        return .result()
    }

    private func saveOptimisticToggle() {
        guard let store = AppGroup.store(), let current = store.load() else { return }
        try? store.save(current.toggled(at: Date()))
    }
}

struct NextTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Track"

    func perform() async throws -> some IntentResult {
        PlayerCommand.next.post()
        return .result()
    }
}

struct LaunchSpotifyIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Spotify"

    func perform() async throws -> some IntentResult {
        PlayerCommand.launchSpotify.post()
        return .result()
    }
}

struct OpenTrackIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Track in Spotify"

    func perform() async throws -> some IntentResult {
        PlayerCommand.openTrack.post()
        return .result()
    }
}
