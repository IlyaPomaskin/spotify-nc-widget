import Foundation

public enum AppGroup {
    private static let infoPlistKey = "AppGroupID"

    public static func containerURL() -> URL? {
        guard let identifier = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String else { return nil }
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    public static func store() -> NowPlayingStore? {
        containerURL().map(NowPlayingStore.init(containerURL:))
    }
}
