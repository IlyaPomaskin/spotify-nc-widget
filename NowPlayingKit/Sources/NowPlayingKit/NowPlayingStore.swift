import Foundation

public struct NowPlayingStore: Sendable {
    private static let stateFileName = "nowplaying.json"
    private static let artworkDirectoryName = "artwork"
    private static let artworkExtension = "jpg"
    private static let spotifyIconFileName = "spotify-icon.png"

    private let containerURL: URL

    public init(containerURL: URL) {
        self.containerURL = containerURL
    }

    private var stateFileURL: URL {
        containerURL.appendingPathComponent(Self.stateFileName)
    }

    private var artworkDirectoryURL: URL {
        containerURL.appendingPathComponent(Self.artworkDirectoryName, isDirectory: true)
    }

    public func save(_ nowPlaying: NowPlaying?) throws {
        guard let nowPlaying else {
            try removeIfExists(stateFileURL)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(nowPlaying).write(to: stateFileURL, options: .atomic)
    }

    public func load() -> NowPlaying? {
        guard let data = try? Data(contentsOf: stateFileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(NowPlaying.self, from: data)
    }

    public func saveArtwork(_ data: Data, trackID: String) throws {
        try FileManager.default.createDirectory(at: artworkDirectoryURL, withIntermediateDirectories: true)
        try data.write(to: artworkPath(trackID: trackID), options: .atomic)
    }

    public func artworkFileURL(trackID: String) -> URL? {
        let url = artworkPath(trackID: trackID)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    public func saveSpotifyIcon(_ data: Data) throws {
        try data.write(to: spotifyIconPath, options: .atomic)
    }

    public func spotifyIconFileURL() -> URL? {
        guard FileManager.default.fileExists(atPath: spotifyIconPath.path) else { return nil }
        return spotifyIconPath
    }

    private var spotifyIconPath: URL {
        containerURL.appendingPathComponent(Self.spotifyIconFileName)
    }

    private func artworkPath(trackID: String) -> URL {
        let safeName = String(trackID.map { $0.isLetter || $0.isNumber ? $0 : "_" })
        return artworkDirectoryURL
            .appendingPathComponent(safeName)
            .appendingPathExtension(Self.artworkExtension)
    }

    private func removeIfExists(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }
}
