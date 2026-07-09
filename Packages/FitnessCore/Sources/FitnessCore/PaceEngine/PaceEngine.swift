import Foundation

/// Tunable knobs for pace tracking and alerting. All field-test tuning happens here.
public struct PaceEngineConfig: Sendable {
    /// Rolling window (seconds) over which current pace is computed, to smooth GPS noise.
    public var paceWindowSeconds: TimeInterval
    /// Alert immediately when required-pace adjustment exceeds this (seconds per mile).
    public var driftThresholdSecPerMile: Double
    /// Also emit a periodic status pulse this often (seconds), even when on pace.
    public var statusPulseInterval: TimeInterval
    /// Never emit two alerts closer together than this (seconds).
    public var minAlertSpacing: TimeInterval
    /// No pace reading (and thus no alerts) until the rolling window spans at
    /// least this long — prevents noise-dominated false alerts early in the run.
    public var warmupSeconds: TimeInterval

    public init(
        paceWindowSeconds: TimeInterval = 45,
        driftThresholdSecPerMile: Double = 10,
        statusPulseInterval: TimeInterval = 180,
        minAlertSpacing: TimeInterval = 60,
        warmupSeconds: TimeInterval = 30
    ) {
        self.paceWindowSeconds = paceWindowSeconds
        self.driftThresholdSecPerMile = driftThresholdSecPerMile
        self.statusPulseInterval = statusPulseInterval
        self.minAlertSpacing = minAlertSpacing
        self.warmupSeconds = warmupSeconds
    }
}

/// One distance observation: elapsed time and cumulative distance covered.
public struct DistanceSample: Sendable {
    /// Seconds since the run started.
    public var elapsed: TimeInterval
    /// Total distance covered so far, in miles.
    public var distanceMiles: Double

    public init(elapsed: TimeInterval, distanceMiles: Double) {
        self.elapsed = elapsed
        self.distanceMiles = distanceMiles
    }
}

/// A coaching alert to surface to the runner (watch haptic + text, or notification).
public struct PaceAlert: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Runner must speed up by `adjustmentSecPerMile` to hit the goal.
        case behind
        /// Within threshold of required pace.
        case onPace
        /// Runner is ahead; could ease off by `adjustmentSecPerMile`.
        case ahead
    }

    public var kind: Kind
    /// Seconds-per-mile difference between current pace and the pace now required
    /// to finish on time. Positive = must run faster.
    public var adjustmentSecPerMile: Double
    /// Projected finish time (seconds) at the current pace.
    public var projectedFinish: TimeInterval
    /// Human-readable coaching message.
    public var message: String
}

/// Tracks progress against a `RunGoal` and decides when to alert.
///
/// Pure logic — feed it `DistanceSample`s (from GPS on the watch, or synthetic
/// traces in tests) and it returns alerts per the configured policy.
public struct PaceEngine: Sendable {
    public let goal: RunGoal
    public let config: PaceEngineConfig

    private var samples: [DistanceSample] = []
    private var lastAlertTime: TimeInterval?

    public init(goal: RunGoal, config: PaceEngineConfig = PaceEngineConfig()) {
        self.goal = goal
        self.config = config
    }

    /// Current pace (seconds per mile) over the rolling window.
    /// `nil` until there is enough movement in the window to measure.
    public var currentPaceSecPerMile: Double? {
        guard let latest = samples.last else { return nil }
        let windowStart = latest.elapsed - config.paceWindowSeconds
        // Use the earliest sample inside the window; fall back to the first
        // sample overall early in the run.
        guard let anchor = samples.first(where: { $0.elapsed >= windowStart }) ?? samples.first,
              anchor.elapsed < latest.elapsed
        else { return nil }
        let dt = latest.elapsed - anchor.elapsed
        let dd = latest.distanceMiles - anchor.distanceMiles
        guard dt >= config.warmupSeconds else { return nil } // window too short to trust
        guard dd > 0.001 else { return nil } // stationary or GPS jitter only
        return dt / dd
    }

    /// Distance still to cover, in miles.
    public var remainingMiles: Double {
        max(0, goal.distance.miles - (samples.last?.distanceMiles ?? 0))
    }

    /// Pace (sec/mi) required over the remaining distance to finish exactly on time.
    /// `nil` when the run is effectively complete.
    public var requiredPaceForRemainderSecPerMile: Double? {
        guard let latest = samples.last, remainingMiles > 0.01 else { return nil }
        let timeLeft = goal.targetTime - latest.elapsed
        return timeLeft / remainingMiles // may be ≤ 0 when the goal is already blown
    }

    /// Projected finish time (seconds) if the current pace holds.
    public var projectedFinish: TimeInterval? {
        guard let latest = samples.last, let pace = currentPaceSecPerMile else { return nil }
        return latest.elapsed + remainingMiles * pace
    }

    /// Ingest a new distance sample; returns an alert when policy says to fire one.
    public mutating func addSample(_ sample: DistanceSample) -> PaceAlert? {
        samples.append(sample)
        // Trim history older than the pace window (keep one sample before it as anchor).
        let cutoff = sample.elapsed - config.paceWindowSeconds
        if let firstInWindow = samples.firstIndex(where: { $0.elapsed >= cutoff }),
           firstInWindow > 1 {
            samples.removeFirst(firstInWindow - 1)
        }
        return evaluate(at: sample.elapsed)
    }

    private mutating func evaluate(at elapsed: TimeInterval) -> PaceAlert? {
        guard let pace = currentPaceSecPerMile,
              let required = requiredPaceForRemainderSecPerMile,
              let projected = projectedFinish
        else { return nil }

        // Positive = need to speed up by this many sec/mi.
        let adjustment = pace - required
        let offPace = abs(adjustment) > config.driftThresholdSecPerMile

        let sinceLast = lastAlertTime.map { elapsed - $0 }
        // Respect minimum spacing between alerts.
        if let sinceLast, sinceLast < config.minAlertSpacing { return nil }
        // Fire on drift, or as a periodic status pulse.
        let pulseDue = sinceLast.map { $0 >= config.statusPulseInterval } ?? true
        guard offPace || pulseDue else { return nil }

        lastAlertTime = elapsed
        let rounded = (abs(adjustment) / 5).rounded() * 5 // coach in 5 s/mi steps

        let kind: PaceAlert.Kind
        let message: String
        if adjustment > config.driftThresholdSecPerMile {
            kind = .behind
            message = "Behind pace — speed up ~\(Int(rounded)) s/mi to hit \(PaceFormatter.timeString(goal.targetTime))"
        } else if adjustment < -config.driftThresholdSecPerMile {
            kind = .ahead
            message = "Ahead of pace — you can ease off ~\(Int(rounded)) s/mi"
        } else {
            kind = .onPace
            message = "On pace — projected finish \(PaceFormatter.timeString(projected))"
        }
        return PaceAlert(
            kind: kind,
            adjustmentSecPerMile: adjustment,
            projectedFinish: projected,
            message: message
        )
    }
}
