import Foundation

public enum PlayerCommand: String, CaseIterable, Sendable {
    case previous, playPause, next, launchSpotify, openTrack

    private static let notificationPrefix = "com.ilyapomaskin.spotifywidget.command."

    public var notificationName: Notification.Name {
        Notification.Name(Self.notificationPrefix + rawValue)
    }

    public init?(notificationName: Notification.Name) {
        guard let match = Self.allCases.first(where: { $0.notificationName == notificationName }) else { return nil }
        self = match
    }

    public func post() {
        DistributedNotificationCenter.default().postNotificationName(
            notificationName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
