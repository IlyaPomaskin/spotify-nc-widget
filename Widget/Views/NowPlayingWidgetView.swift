import SwiftUI
import WidgetKit

struct NowPlayingWidgetView: View {
    let entry: NowPlayingEntry

    var body: some View {
        content
            .overlay(alignment: .topTrailing) {
                SpotifyBadge(icon: entry.spotifyIcon)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let nowPlaying = entry.nowPlaying {
            MediumView(nowPlaying: nowPlaying, artwork: entry.artwork)
        } else {
            NotPlayingView()
        }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    NowPlayingWidget()
} timeline: {
    NowPlayingEntry.sample
    NowPlayingEntry.longTitleSample
    NowPlayingEntry(date: .now, nowPlaying: nil, artwork: nil)
}
#endif
