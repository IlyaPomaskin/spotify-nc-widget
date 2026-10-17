import XCTest
@testable import NowPlayingKit

final class NowPlayingTests: XCTestCase {
    private let capturedAt = Date(timeIntervalSince1970: 1_000_000)

    private func output(_ fields: [String]) -> String {
        fields.joined(separator: NowPlaying.fieldSeparator)
    }

    private func playingFields(state: String = "playing", artwork: String = "https://i.scdn.co/a.jpg") -> [String] {
        [state, "spotify:track:1", "Midnight City", "M83", "Hurry Up", "243000", "91.5", artwork]
    }

    func test_parse_playing() throws {
        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: output(playingFields()), capturedAt: capturedAt))

        XCTAssertEqual(nowPlaying.state, .playing)
        XCTAssertEqual(nowPlaying.trackID, "spotify:track:1")
        XCTAssertEqual(nowPlaying.title, "Midnight City")
        XCTAssertEqual(nowPlaying.artist, "M83")
        XCTAssertEqual(nowPlaying.album, "Hurry Up")
        XCTAssertEqual(nowPlaying.durationSeconds, 243)
        XCTAssertEqual(nowPlaying.positionSeconds, 91.5)
        XCTAssertEqual(nowPlaying.artworkURL, URL(string: "https://i.scdn.co/a.jpg"))
    }

    func test_parse_paused() throws {
        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: output(playingFields(state: "paused")), capturedAt: capturedAt))

        XCTAssertEqual(nowPlaying.state, .paused)
    }

    func test_parse_stopped() {
        XCTAssertNil(NowPlaying.parse(appleScriptOutput: output(playingFields(state: "stopped")), capturedAt: capturedAt))
    }

    func test_parse_missing_artwork() throws {
        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: output(playingFields(artwork: "")), capturedAt: capturedAt))

        XCTAssertNil(nowPlaying.artworkURL)
    }

    func test_parse_malformed() {
        XCTAssertNil(NowPlaying.parse(appleScriptOutput: output(["playing", "id", "title"]), capturedAt: capturedAt))

        var badDuration = playingFields()
        badDuration[5] = "abc"
        XCTAssertNil(NowPlaying.parse(appleScriptOutput: output(badDuration), capturedAt: capturedAt))
    }

    func test_parse_trims_trailing_newline() throws {
        let raw = output(playingFields()) + "\n"

        XCTAssertNotNil(NowPlaying.parse(appleScriptOutput: raw, capturedAt: capturedAt))
    }

    func test_progress_playing() throws {
        var fields = playingFields()
        fields[6] = "10"
        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: output(fields), capturedAt: capturedAt))

        XCTAssertEqual(nowPlaying.elapsedSeconds(at: capturedAt.addingTimeInterval(5)), 15)
        XCTAssertEqual(nowPlaying.elapsedSeconds(at: capturedAt.addingTimeInterval(10_000)), 243)
        XCTAssertEqual(nowPlaying.startDate, capturedAt.addingTimeInterval(-10))
        XCTAssertEqual(nowPlaying.endDate, capturedAt.addingTimeInterval(233))
    }

    func test_progress_paused() throws {
        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: output(playingFields(state: "paused")), capturedAt: capturedAt))

        XCTAssertEqual(nowPlaying.elapsedSeconds(at: capturedAt.addingTimeInterval(60)), 91.5)
    }

    func test_command_names() {
        XCTAssertEqual(PlayerCommand.next.notificationName.rawValue, "com.ilyapomaskin.spotifywidget.command.next")
        XCTAssertEqual(PlayerCommand.playPause.notificationName.rawValue, "com.ilyapomaskin.spotifywidget.command.playPause")
        XCTAssertEqual(PlayerCommand(notificationName: PlayerCommand.openTrack.notificationName), .openTrack)
    }
}
