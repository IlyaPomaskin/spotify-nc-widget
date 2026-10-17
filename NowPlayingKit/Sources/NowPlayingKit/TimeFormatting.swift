import Foundation

public enum TimeFormatting {
    private static let secondsPerMinute = 60
    private static let secondsPerHour = 3600

    public static func string(seconds: Double) -> String {
        let total = max(Int(seconds), 0)
        let hours = total / secondsPerHour
        let minutes = (total % secondsPerHour) / secondsPerMinute
        let remainder = total % secondsPerMinute
        guard hours > 0 else { return String(format: "%d:%02d", minutes, remainder) }
        return String(format: "%d:%02d:%02d", hours, minutes, remainder)
    }
}
