import NowPlayingKit
import SwiftUI

struct SmallView: View {
    let nowPlaying: NowPlaying
    let artwork: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TappableArtworkView(image: artwork, cornerRadius: 8)
                    .frame(width: 44, height: 44)
                TrackTextView(title: nowPlaying.title, subtitle: nowPlaying.artist, titleFont: .caption, subtitleFont: .caption2)
                    .padding(.trailing, SpotifyBadge.size)
            }
            Spacer(minLength: 0)
            TrackTimelineView(nowPlaying: nowPlaying, showsTimeLabels: false)
            ControlsView(isPlaying: nowPlaying.isPlaying, spacing: 16, iconSize: 14)
        }
    }
}

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

struct LargeView: View {
    let nowPlaying: NowPlaying
    let artwork: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TappableArtworkView(image: artwork, cornerRadius: 14)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
            TrackTextView(
                title: nowPlaying.title,
                subtitle: "\(nowPlaying.artist) — \(nowPlaying.album)",
                titleFont: .headline,
                subtitleFont: .subheadline
            )
            TrackTimelineView(nowPlaying: nowPlaying, showsTimeLabels: true)
            ControlsView(isPlaying: nowPlaying.isPlaying, spacing: 32, iconSize: 18)
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
