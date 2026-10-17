import Foundation

public struct NowPlaying: Codable, Equatable, Sendable {
    public enum State: String, Codable, Sendable {
        case playing, paused, stopped
    }

    public static let fieldSeparator = "\u{1F}"

    private static let fieldCount = 8
    private static let millisecondsPerSecond = 1000.0

    public let trackID: String
    public let title: String
    public let artist: String
    public let album: String
    public let durationSeconds: Double
    public let positionSeconds: Double
    public let capturedAt: Date
    public let state: State
    public let artworkURL: URL?

    public init(
        trackID: String,
        title: String,
        artist: String,
        album: String,
        durationSeconds: Double,
        positionSeconds: Double,
        capturedAt: Date,
        state: State,
        artworkURL: URL?
    ) {
        self.trackID = trackID
        self.title = title
        self.artist = artist
        self.album = album
        self.durationSeconds = durationSeconds
        self.positionSeconds = positionSeconds
        self.capturedAt = capturedAt
        self.state = state
        self.artworkURL = artworkURL
    }

    /// Fields: state, trackID, title, artist, album, durationMs, positionSeconds, artworkURL.
    public static func parse(appleScriptOutput: String, capturedAt: Date) -> NowPlaying? {
        let fields = appleScriptOutput
            .trimmingCharacters(in: .newlines)
            .components(separatedBy: fieldSeparator)
        guard fields.count == fieldCount else { return nil }
        guard let state = State(rawValue: fields[0]), state != .stopped else { return nil }
        guard let durationMs = number(fields[5]), let position = number(fields[6]) else { return nil }

        return NowPlaying(
            trackID: fields[1],
            title: fields[2],
            artist: fields[3],
            album: fields[4],
            durationSeconds: durationMs / millisecondsPerSecond,
            positionSeconds: position,
            capturedAt: capturedAt,
            state: state,
            artworkURL: URL(string: fields[7])
        )
    }

    private static func number(_ field: String) -> Double? {
        Double(field.replacingOccurrences(of: ",", with: "."))
    }

    public var isPlaying: Bool { state == .playing }

    public func toggled(at date: Date) -> NowPlaying {
        NowPlaying(
            trackID: trackID,
            title: title,
            artist: artist,
            album: album,
            durationSeconds: durationSeconds,
            positionSeconds: elapsedSeconds(at: date),
            capturedAt: date,
            state: isPlaying ? .paused : .playing,
            artworkURL: artworkURL
        )
    }

    public func isEquivalent(to other: NowPlaying, tolerance: TimeInterval = 2) -> Bool {
        let hasSameMetadata = trackID == other.trackID
            && title == other.title
            && artist == other.artist
            && album == other.album
            && durationSeconds == other.durationSeconds
            && state == other.state
            && artworkURL == other.artworkURL
        guard hasSameMetadata else { return false }

        let comparisonDate = max(capturedAt, other.capturedAt)
        let drift = abs(elapsedSeconds(at: comparisonDate) - other.elapsedSeconds(at: comparisonDate))
        return drift <= tolerance
    }

    public var startDate: Date { capturedAt.addingTimeInterval(-positionSeconds) }

    public var endDate: Date { startDate.addingTimeInterval(durationSeconds) }

    public func elapsedSeconds(at date: Date) -> Double {
        guard isPlaying else { return clamped(positionSeconds) }
        return clamped(date.timeIntervalSince(startDate))
    }

    private func clamped(_ seconds: Double) -> Double {
        min(max(seconds, 0), durationSeconds)
    }
}
