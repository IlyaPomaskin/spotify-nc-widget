import SwiftUI
import WidgetKit

@main
struct SpotifyWidgetBundle: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
    }
}

struct NowPlayingWidget: Widget {
    private static let kind = "NowPlayingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: Provider()) { entry in
            NowPlayingWidgetView(entry: entry)
                .environment(\.colorScheme, .dark)
                .containerBackground(WidgetStyle.background, for: .widget)
        }
        .configurationDisplayName("Spotify")
        .description("Now playing in Spotify, with playback controls.")
        .supportedFamilies([.systemMedium])
    }
}
