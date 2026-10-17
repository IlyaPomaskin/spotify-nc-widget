import AppKit
import NowPlayingKit

@MainActor
final class SpotifyController {
    static let bundleIdentifier = "com.spotify.client"

    private static let fetchScriptSource = """
    tell application "Spotify"
        set separator to (ASCII character 31)
        set currentState to player state as string
        if currentState is "stopped" then return currentState
        set currentTrack to current track
        set artworkLink to ""
        try
            set artworkLink to artwork url of currentTrack
            if artworkLink is missing value then set artworkLink to ""
        end try
        return currentState & separator & (id of currentTrack) & separator & (name of currentTrack) & separator & (artist of currentTrack) & separator & (album of currentTrack) & separator & ((duration of currentTrack) as string) & separator & ((player position) as string) & separator & artworkLink
    end tell
    """

    private static let commandScriptSources: [PlayerCommand: String] = [
        .previous: "tell application \"Spotify\" to previous track",
        .playPause: "tell application \"Spotify\" to playpause",
        .next: "tell application \"Spotify\" to next track",
    ]

    private let fetchScript = SpotifyController.compiled(SpotifyController.fetchScriptSource)
    private let commandScripts = SpotifyController.commandScriptSources.compactMapValues(SpotifyController.compiled)

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleIdentifier).isEmpty
    }

    func fetch() -> NowPlaying? {
        guard isRunning, let fetchScript else { return nil }
        var error: NSDictionary?
        let result = fetchScript.executeAndReturnError(&error)
        if let error {
            NSLog("SpotifyWidget: fetch failed: \(error)")
            return nil
        }
        guard let output = result.stringValue else { return nil }
        return NowPlaying.parse(appleScriptOutput: output, capturedAt: Date())
    }

    func perform(_ command: PlayerCommand) {
        guard command != .launchSpotify else {
            launchSpotify()
            return
        }
        guard command != .openTrack else {
            openCurrentTrack()
            return
        }
        guard isRunning, let script = commandScripts[command] else { return }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        if let error {
            NSLog("SpotifyWidget: command \(command.rawValue) failed: \(error)")
        }
    }

    private static func compiled(_ source: String) -> NSAppleScript? {
        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        script?.compileAndReturnError(&error)
        if let error {
            NSLog("SpotifyWidget: script compile failed: \(error)")
        }
        return script
    }

    func iconPNGData() -> Data? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleIdentifier) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Self.iconPixelSide,
            pixelsHigh: Self.iconPixelSide,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        let rect = NSRect(x: 0, y: 0, width: Self.iconPixelSide, height: Self.iconPixelSide)
        bitmap.size = rect.size

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        context?.imageInterpolation = .high
        NSGraphicsContext.current = context
        icon.draw(in: rect, from: .zero, operation: .copy, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high.rawValue])
        context?.flushGraphics()

        return bitmap.representation(using: .png, properties: [:])
    }

    private static let iconPixelSide = 256

    private func openCurrentTrack() {
        guard let trackURL = fetch().flatMap({ URL(string: $0.trackID) }) else {
            launchSpotify()
            return
        }
        NSWorkspace.shared.open(trackURL)
    }

    private func launchSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleIdentifier) else {
            NSLog("SpotifyWidget: Spotify is not installed")
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}
