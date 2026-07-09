import Foundation

/// Standard race distances, in miles.
public enum RaceDistance: Codable, Hashable, Sendable {
    case fiveK
    case tenK
    case halfMarathon
    case marathon
    case custom(miles: Double)

    public var miles: Double {
        switch self {
        case .fiveK: return 3.10686
        case .tenK: return 6.21371
        case .halfMarathon: return 13.1094
        case .marathon: return 26.2188
        case .custom(let miles): return miles
        }
    }

    public var displayName: String {
        switch self {
        case .fiveK: return "5K"
        case .tenK: return "10K"
        case .halfMarathon: return "Half Marathon"
        case .marathon: return "Marathon"
        case .custom(let miles): return String(format: "%.2f mi", miles)
        }
    }
}

/// A run goal: cover `distance` in `targetTime` seconds.
public struct RunGoal: Codable, Hashable, Sendable {
    public var distance: RaceDistance
    /// Total goal time in seconds.
    public var targetTime: TimeInterval

    public init(distance: RaceDistance, targetTime: TimeInterval) {
        self.distance = distance
        self.targetTime = targetTime
    }

    /// Average pace required to hit the goal, in seconds per mile.
    public var requiredPaceSecPerMile: Double {
        targetTime / distance.miles
    }
}

/// Formatting helpers shared by phone and watch UI.
public enum PaceFormatter {
    /// "9:39 /mi" from seconds-per-mile.
    public static func paceString(secPerMile: Double) -> String {
        guard secPerMile.isFinite, secPerMile > 0 else { return "--:-- /mi" }
        let total = Int(secPerMile.rounded())
        return String(format: "%d:%02d /mi", total / 60, total % 60)
    }

    /// "30:00" or "1:52:30" from seconds.
    public static func timeString(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "--:--" }
        let total = Int(seconds.rounded())
        let (h, m, s) = (total / 3600, (total % 3600) / 60, total % 60)
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
}
