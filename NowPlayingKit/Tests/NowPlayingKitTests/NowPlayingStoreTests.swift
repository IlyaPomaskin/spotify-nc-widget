import XCTest
@testable import NowPlayingKit

final class NowPlayingStoreTests: XCTestCase {
    private var containerURL: URL!
    private var store: NowPlayingStore!

    override func setUpWithError() throws {
        containerURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true)
        store = NowPlayingStore(containerURL: containerURL)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: containerURL)
    }

    private let sample = NowPlaying(
        trackID: "spotify:track:1",
        title: "Midnight City",
        artist: "M83",
        album: "Hurry Up",
        durationSeconds: 243,
        positionSeconds: 10,
        capturedAt: Date(timeIntervalSince1970: 1_000_000),
        state: .playing,
        artworkURL: URL(string: "https://i.scdn.co/a.jpg")
    )

    func test_store_roundtrip() throws {
        try store.save(sample)
        XCTAssertEqual(store.load(), sample)

        try store.save(nil)
        XCTAssertNil(store.load())
    }

    func test_store_artwork() throws {
        XCTAssertNil(store.artworkFileURL(trackID: "spotify:track:1"))

        try store.saveArtwork(Data([1, 2, 3]), trackID: "spotify:track:1")

        let url = try XCTUnwrap(store.artworkFileURL(trackID: "spotify:track:1"))
        XCTAssertEqual(try Data(contentsOf: url), Data([1, 2, 3]))
        XCTAssertNil(store.artworkFileURL(trackID: "spotify:track:2"))
    }

    func test_store_save_nil_without_file_does_not_throw() {
        XCTAssertNoThrow(try store.save(nil))
    }

    func test_store_spotify_icon() throws {
        XCTAssertNil(store.spotifyIconFileURL())

        try store.saveSpotifyIcon(Data([9, 9]))

        let url = try XCTUnwrap(store.spotifyIconFileURL())
        XCTAssertEqual(try Data(contentsOf: url), Data([9, 9]))
    }
}
