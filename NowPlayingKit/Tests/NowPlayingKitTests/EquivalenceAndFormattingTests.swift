import XCTest
@testable import NowPlayingKit

final class EquivalenceAndFormattingTests: XCTestCase {
    private let capturedAt = Date(timeIntervalSince1970: 1_000_000)

    private func make(
        trackID: String = "spotify:track:1",
        position: Double = 10,
        capturedAt: Date? = nil,
        state: NowPlaying.State = .playing
    ) -> NowPlaying {
        NowPlaying(
            trackID: trackID,
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up",
            durationSeconds: 243,
            positionSeconds: position,
            capturedAt: capturedAt ?? self.capturedAt,
            state: state,
            artworkURL: nil
        )
    }

    func test_equivalent_when_position_follows_clock() {
        let later = make(position: 15, capturedAt: capturedAt.addingTimeInterval(5))

        XCTAssertTrue(make().isEquivalent(to: later))
    }

    func test_not_equivalent_after_seek() {
        let seeked = make(position: 120, capturedAt: capturedAt.addingTimeInterval(5))

        XCTAssertFalse(make().isEquivalent(to: seeked))
    }

    func test_not_equivalent_on_state_or_track_change() {
        XCTAssertFalse(make().isEquivalent(to: make(state: .paused)))
        XCTAssertFalse(make().isEquivalent(to: make(trackID: "spotify:track:2")))
    }

    func test_paused_equivalent_regardless_of_capture_time() {
        let paused = make(state: .paused)
        let pausedLater = make(capturedAt: capturedAt.addingTimeInterval(60), state: .paused)

        XCTAssertTrue(paused.isEquivalent(to: pausedLater))
    }

    func test_parse_accepts_comma_decimal() throws {
        let raw = ["playing", "id", "t", "a", "al", "243000", "91,5", ""].joined(separator: NowPlaying.fieldSeparator)

        let nowPlaying = try XCTUnwrap(NowPlaying.parse(appleScriptOutput: raw, capturedAt: capturedAt))
        XCTAssertEqual(nowPlaying.positionSeconds, 91.5)
    }

    func test_time_formatting() {
        XCTAssertEqual(TimeFormatting.string(seconds: 0), "0:00")
        XCTAssertEqual(TimeFormatting.string(seconds: 91.7), "1:31")
        XCTAssertEqual(TimeFormatting.string(seconds: 3725), "1:02:05")
        XCTAssertEqual(TimeFormatting.string(seconds: -5), "0:00")
    }
}

final class ToggleTests: XCTestCase {
    private let capturedAt = Date(timeIntervalSince1970: 1_000_000)

    private func make(state: NowPlaying.State) -> NowPlaying {
        NowPlaying(
            trackID: "id", title: "t", artist: "a", album: "al",
            durationSeconds: 243, positionSeconds: 10,
            capturedAt: capturedAt, state: state, artworkURL: nil
        )
    }

    func test_toggle_playing_freezes_at_current_position() {
        let toggled = make(state: .playing).toggled(at: capturedAt.addingTimeInterval(5))

        XCTAssertEqual(toggled.state, .paused)
        XCTAssertEqual(toggled.positionSeconds, 15)
        XCTAssertEqual(toggled.capturedAt, capturedAt.addingTimeInterval(5))
    }

    func test_toggle_paused_resumes_from_same_position() {
        let resumeDate = capturedAt.addingTimeInterval(60)
        let toggled = make(state: .paused).toggled(at: resumeDate)

        XCTAssertEqual(toggled.state, .playing)
        XCTAssertEqual(toggled.positionSeconds, 10)
        XCTAssertEqual(toggled.elapsedSeconds(at: resumeDate.addingTimeInterval(3)), 13)
    }
}
