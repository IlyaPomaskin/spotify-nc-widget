import AppKit
import NowPlayingKit
import WidgetKit

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let nowPlaying: NowPlaying?
    let artwork: NSImage?
    var spotifyIcon: NSImage? = nil
}

extension NowPlayingEntry {
    static let sample = NowPlayingEntry(
        date: Date(),
        nowPlaying: NowPlaying(
            trackID: "sample",
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            durationSeconds: 243,
            positionSeconds: 91,
            capturedAt: Date(),
            state: .playing,
            artworkURL: nil
        ),
        artwork: nil
    )
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        let entry = currentEntry()
        guard context.isPreview, entry.nowPlaying == nil else {
            completion(entry)
            return
        }
        completion(.sample)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> NowPlayingEntry {
        let store = AppGroup.store()
        let spotifyIcon = store?.spotifyIconFileURL().flatMap(NSImage.init(contentsOf:))
        guard let store, let nowPlaying = store.load() else {
            return NowPlayingEntry(date: Date(), nowPlaying: nil, artwork: nil, spotifyIcon: spotifyIcon)
        }
        let artwork = store.artworkFileURL(trackID: nowPlaying.trackID).flatMap(NSImage.init(contentsOf:))
        return NowPlayingEntry(date: Date(), nowPlaying: nowPlaying, artwork: artwork, spotifyIcon: spotifyIcon)
    }
}
