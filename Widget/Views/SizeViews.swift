import NowPlayingKit
import SwiftUI

struct MediumView: View {
    let nowPlaying: NowPlaying
    let artwork: NSImage?

    var body: some View {
        HStack(spacing: 12) {
            TappableArtworkView(image: artwork, cornerRadius: 10)
                .aspectRatio(1, contentMode: .fit)
            VStack(alignment: .leading, spacing: 4) {
                TrackTextView(title: nowPlaying.title, subtitle: nowPlaying.artist, titleFont: .subheadline, subtitleFont: .caption)
                    .padding(.trailing, SpotifyBadge.size)
                Spacer(minLength: 0)
                TrackTimelineView(nowPlaying: nowPlaying, showsTimeLabels: true)
                ControlsView(isPlaying: nowPlaying.isPlaying, spacing: 22, iconSize: 16)
                    .padding(.top, 2)
            }
        }
    }
}

struct NotPlayingView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: WidgetStyle.placeholderSymbol)
                .font(.title2)
                .foregroundStyle(WidgetStyle.secondaryText)
            Text("Not playing")
                .font(.caption)
                .foregroundStyle(WidgetStyle.secondaryText)
            Button(intent: LaunchSpotifyIntent()) {
                PlayCircleIcon(isPlaying: false, glyphSize: 14)
            }
            .buttonStyle(ControlButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension NowPlayingEntry {
    static let longTitleSample = NowPlayingEntry(
        date: Date(),
        nowPlaying: NowPlaying(
            trackID: "long",
            title: String(repeating: "Very Long Track Title ", count: 6),
            artist: String(repeating: "Artist Name ", count: 6),
            album: "Album",
            durationSeconds: 3725,
            positionSeconds: 30,
            capturedAt: Date(),
            state: .paused,
            artworkURL: nil
        ),
        artwork: nil
    )
}
