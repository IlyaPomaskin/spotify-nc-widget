import SwiftUI
import WidgetKit

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NowPlayingEntry

    private static let largeBadgeInset: CGFloat = 8

    var body: some View {
        content
            .overlay(alignment: .topTrailing) {
                SpotifyBadge(icon: entry.spotifyIcon)
                    .padding(badgeInset)
            }
    }

    private var badgeInset: CGFloat {
        guard family == .systemLarge, entry.nowPlaying != nil else { return 0 }
        return Self.largeBadgeInset
    }

    @ViewBuilder
    private var content: some View {
        if let nowPlaying = entry.nowPlaying {
            switch family {
            case .systemMedium:
                MediumView(nowPlaying: nowPlaying, artwork: entry.artwork)
            case .systemLarge:
                LargeView(nowPlaying: nowPlaying, artwork: entry.artwork)
            default:
                SmallView(nowPlaying: nowPlaying, artwork: entry.artwork)
            }
        } else {
            NotPlayingView()
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    NowPlayingWidget()
} timeline: {
    NowPlayingEntry.sample
    NowPlayingEntry.longTitleSample
    NowPlayingEntry(date: .now, nowPlaying: nil, artwork: nil)
}

#Preview(as: .systemMedium) {
    NowPlayingWidget()
} timeline: {
    NowPlayingEntry.sample
    NowPlayingEntry.longTitleSample
}

#Preview(as: .systemLarge) {
    NowPlayingWidget()
} timeline: {
    NowPlayingEntry.sample
    NowPlayingEntry.longTitleSample
}
#endif
