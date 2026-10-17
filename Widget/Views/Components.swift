import AppIntents
import NowPlayingKit
import SwiftUI

enum WidgetStyle {
    static let accent = Color(hex: 0x1ED760)
    static let background = Color(hex: 0x121212)
    static let placeholderBackground = Color(hex: 0x282828)
    static let primaryText = Color.white
    static let secondaryText = Color(hex: 0xB3B3B3)
    static let placeholderSymbol = "music.note"
}

private extension Color {
    private static let channelMax = 255.0

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / Self.channelMax,
            green: Double((hex >> 8) & 0xFF) / Self.channelMax,
            blue: Double(hex & 0xFF) / Self.channelMax
        )
    }
}

struct ArtworkView: View {
    let image: NSImage?
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    WidgetStyle.placeholderBackground
                    Image(systemName: WidgetStyle.placeholderSymbol)
                        .font(.title)
                        .foregroundStyle(WidgetStyle.secondaryText)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct SpotifyBadge: View {
    let icon: NSImage?
    let size: CGFloat

    var body: some View {
        Button(intent: LaunchSpotifyIntent()) {
            badgeImage
                .frame(width: size, height: size)
                .contentShape(Rectangle())
        }
        .buttonStyle(ControlButtonStyle())
    }

    @ViewBuilder
    private var badgeImage: some View {
        if let icon {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: WidgetStyle.placeholderSymbol)
                .font(.system(size: size * 0.55, weight: .bold))
                .foregroundStyle(Color.black)
                .frame(width: size, height: size)
                .background(Circle().fill(WidgetStyle.accent))
        }
    }
}

struct TappableArtworkView: View {
    let image: NSImage?
    let cornerRadius: CGFloat

    var body: some View {
        Button(intent: OpenTrackIntent()) {
            ArtworkView(image: image, cornerRadius: cornerRadius)
        }
        .buttonStyle(ControlButtonStyle())
    }
}

struct TrackTextView: View {
    static let lineSpacing: CGFloat = 2

    let title: String
    let subtitle: String
    let titleFont: Font
    let subtitleFont: Font

    var body: some View {
        VStack(alignment: .leading, spacing: Self.lineSpacing) {
            Text(title)
                .font(titleFont.weight(.bold))
                .foregroundStyle(WidgetStyle.primaryText)
            Text(subtitle)
                .font(subtitleFont)
                .foregroundStyle(WidgetStyle.secondaryText)
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TrackTimelineView: View {
    // ProgressView(timerInterval:) reserves extra space below the bar; a fixed top-aligned height keeps both states identical.
    private static let barHeight: CGFloat = 4
    private static let barToTimeSpacing: CGFloat = 6
    private static let minimumDuration: TimeInterval = 1
    // ProgressView(timerInterval:) has no pause; stretching the interval makes it advance imperceptibly while paused.
    private static let pausedStretchFactor: TimeInterval = 1_000_000

    let nowPlaying: NowPlaying
    let showsTimeLabels: Bool

    var body: some View {
        VStack(spacing: Self.barToTimeSpacing) {
            ProgressView(timerInterval: barInterval, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(WidgetStyle.accent)
            .frame(height: Self.barHeight, alignment: .top)
            .contentTransition(.identity)
            .transaction { transaction in
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
            if showsTimeLabels {
                timeLabels
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(WidgetStyle.secondaryText)
            }
        }
    }

    private var duration: TimeInterval {
        max(nowPlaying.durationSeconds, Self.minimumDuration)
    }

    private var elapsed: TimeInterval {
        nowPlaying.elapsedSeconds(at: nowPlaying.capturedAt)
    }

    private var trackInterval: ClosedRange<Date> {
        let start = nowPlaying.capturedAt.addingTimeInterval(-elapsed)
        return start...start.addingTimeInterval(duration)
    }

    private var barInterval: ClosedRange<Date> {
        guard !nowPlaying.isPlaying else { return trackInterval }
        let start = nowPlaying.capturedAt.addingTimeInterval(-elapsed * Self.pausedStretchFactor)
        return start...start.addingTimeInterval(duration * Self.pausedStretchFactor)
    }

    private var pauseTime: Date? {
        nowPlaying.isPlaying ? nil : nowPlaying.capturedAt
    }

    private var timeLabels: some View {
        HStack(spacing: 0) {
            Text(timerInterval: trackInterval, pauseTime: pauseTime, countsDown: false, showsHours: true)
                .leadingAligned()
            Text(TimeFormatting.string(seconds: nowPlaying.durationSeconds))
                .trailingAligned()
        }
    }
}

private extension View {
    func leadingAligned() -> some View {
        multilineTextAlignment(.leading).frame(maxWidth: .infinity, alignment: .leading)
    }

    func trailingAligned() -> some View {
        multilineTextAlignment(.trailing).frame(maxWidth: .infinity, alignment: .trailing)
    }
}

struct ControlButtonStyle: ButtonStyle {
    private static let pressedScale: CGFloat = 0.92
    private static let pressedOpacity: Double = 0.7

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Self.pressedScale : 1)
            .opacity(configuration.isPressed ? Self.pressedOpacity : 1)
    }
}

struct PlayCircleIcon: View {
    private static let circleScale: CGFloat = 2

    let isPlaying: Bool
    let glyphSize: CGFloat

    var body: some View {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: glyphSize, weight: .bold))
            .foregroundStyle(Color.black)
            .frame(width: glyphSize * Self.circleScale, height: glyphSize * Self.circleScale)
            .background(Circle().fill(WidgetStyle.accent))
            .contentShape(Circle())
    }
}

struct ControlsView: View {
    private static let skipFrameScale: CGFloat = 1.6

    let isPlaying: Bool
    let spacing: CGFloat
    let iconSize: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            Button(intent: PreviousTrackIntent()) {
                skipIcon("backward.end.fill")
            }
            Button(intent: PlayPauseIntent()) {
                PlayCircleIcon(isPlaying: isPlaying, glyphSize: iconSize)
            }
            Button(intent: NextTrackIntent()) {
                skipIcon("forward.end.fill")
            }
        }
        .buttonStyle(ControlButtonStyle())
        .frame(maxWidth: .infinity)
    }

    private func skipIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: iconSize))
            .foregroundStyle(WidgetStyle.secondaryText)
            .frame(width: iconSize * Self.skipFrameScale, height: iconSize * Self.skipFrameScale)
            .contentShape(Rectangle())
    }
}
