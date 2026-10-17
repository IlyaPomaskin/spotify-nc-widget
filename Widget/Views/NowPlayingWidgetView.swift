import SwiftUI
import WidgetKit

struct NowPlayingWidgetView: View {
    let entry: NowPlayingEntry

    var body: some View {
        if let nowPlaying = entry.nowPlaying {
            MediumView(nowPlaying: nowPlaying, artwork: entry.artwork, spotifyIcon: entry.spotifyIcon)
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
