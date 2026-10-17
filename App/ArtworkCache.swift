import Foundation
import NowPlayingKit

actor ArtworkCache {
    private let store: NowPlayingStore

    init(store: NowPlayingStore) {
        self.store = store
    }

    func ensureArtwork(for nowPlaying: NowPlaying) async {
        guard let url = nowPlaying.artworkURL else { return }
        guard store.artworkFileURL(trackID: nowPlaying.trackID) == nil else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try store.saveArtwork(data, trackID: nowPlaying.trackID)
        } catch {
            NSLog("SpotifyWidget: artwork download failed: \(error)")
        }
    }
}
