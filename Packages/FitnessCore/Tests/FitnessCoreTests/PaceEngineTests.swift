import Foundation
import Testing
@testable import FitnessCore

/// Generates a synthetic GPS trace at a constant pace, one sample per `interval` seconds.
private func steadySamples(
    paceSecPerMile: Double,
    duration: TimeInterval,
    interval: TimeInterval = 5
) -> [DistanceSample] {
    stride(from: interval, through: duration, by: interval).map { t in
        DistanceSample(elapsed: t, distanceMiles: t / paceSecPerMile)
    }
}

@Suite("RunGoal")
struct RunGoalTests {
    @Test func requiredPaceFor30Min5K() {
        let goal = RunGoal(distance: .fiveK, targetTime: 30 * 60)
        // 30:00 over 3.10686 mi ≈ 9:39/mi
        #expect(abs(goal.requiredPaceSecPerMile - 579.36) < 0.5)
    }

    @Test func paceFormatting() {
        #expect(PaceFormatter.paceString(secPerMile: 579.4) == "9:39 /mi")
        #expect(PaceFormatter.timeString(30 * 60) == "30:00")
        #expect(PaceFormatter.timeString(112.5 * 60) == "1:52:30")
    }
}

@Suite("PaceEngine")
struct PaceEngineTests {
    let goal = RunGoal(distance: .fiveK, targetTime: 30 * 60) // ~579 s/mi required

    @Test func noPaceBeforeMovement() {
        var engine = PaceEngine(goal: goal)
        _ = engine.addSample(DistanceSample(elapsed: 1, distanceMiles: 0))
        #expect(engine.currentPaceSecPerMile == nil)
    }

    @Test func steadyOnPaceRunReportsOnPace() {
        var engine = PaceEngine(goal: goal)
        var alerts: [PaceAlert] = []
        for sample in steadySamples(paceSecPerMile: 579, duration: 600) {
            if let alert = engine.addSample(sample) { alerts.append(alert) }
        }
        #expect(!alerts.isEmpty)
        #expect(alerts.allSatisfy { $0.kind == .onPace })
        // Rolling pace should closely track the true pace.
        #expect(abs(engine.currentPaceSecPerMile! - 579) < 2)
    }

    @Test func slowRunnerToldToSpeedUp() {
        var engine = PaceEngine(goal: goal)
        var alerts: [PaceAlert] = []
        // Running 11:00/mi against a ~9:39/mi goal.
        for sample in steadySamples(paceSecPerMile: 660, duration: 600) {
            if let alert = engine.addSample(sample) { alerts.append(alert) }
        }
        let behind = alerts.filter { $0.kind == .behind }
        #expect(!behind.isEmpty)
        // Needs to make up roughly 80+ s/mi (and more as time passes).
        #expect(behind.first!.adjustmentSecPerMile > 60)
        #expect(behind.first!.message.contains("speed up"))
    }

    @Test func fastRunnerToldTheyAreAhead() {
        var engine = PaceEngine(goal: goal)
        var alerts: [PaceAlert] = []
        // Running 8:00/mi against a ~9:39/mi goal.
        for sample in steadySamples(paceSecPerMile: 480, duration: 600) {
            if let alert = engine.addSample(sample) { alerts.append(alert) }
        }
        #expect(alerts.contains { $0.kind == .ahead })
    }

    @Test func alertsRespectMinimumSpacing() {
        let config = PaceEngineConfig(minAlertSpacing: 60)
        var engine = PaceEngine(goal: goal, config: config)
        var alertTimes: [TimeInterval] = []
        // Badly off pace the whole run → constant pressure to alert.
        for sample in steadySamples(paceSecPerMile: 720, duration: 900) {
            if engine.addSample(sample) != nil { alertTimes.append(sample.elapsed) }
        }
        #expect(alertTimes.count > 1)
        for (a, b) in zip(alertTimes, alertTimes.dropFirst()) {
            #expect(b - a >= 60)
        }
    }

    @Test func statusPulseFiresWhenOnPace() {
        let config = PaceEngineConfig(statusPulseInterval: 180)
        var engine = PaceEngine(goal: goal, config: config)
        var alertTimes: [TimeInterval] = []
        for sample in steadySamples(paceSecPerMile: 579, duration: 600) {
            if engine.addSample(sample) != nil { alertTimes.append(sample.elapsed) }
        }
        // Expect pulses roughly every 180 s over a 600 s run (first ≈ start).
        #expect(alertTimes.count >= 3)
        for (a, b) in zip(alertTimes.dropFirst(), alertTimes.dropFirst(2)) {
            #expect(b - a >= 180)
        }
    }

    @Test func noisyGPSDoesNotFlipAlerts() {
        var engine = PaceEngine(goal: goal)
        var kinds: Set<PaceAlert.Kind> = []
        // Realistic GPS noise: cumulative distance is monotone, but each 5 s
        // increment is off by ±10%. Over the 45 s smoothing window the errors
        // largely cancel, so every alert should stay .onPace.
        var noisy: [DistanceSample] = []
        var distance = 0.0
        var t = 5.0
        var i = 0
        while t <= 600 {
            let trueIncrement = 5.0 / 579.0
            distance += trueIncrement * (i % 2 == 0 ? 1.10 : 0.90)
            noisy.append(DistanceSample(elapsed: t, distanceMiles: distance))
            t += 5
            i += 1
        }
        for sample in noisy {
            if let alert = engine.addSample(sample) { kinds.insert(alert.kind) }
        }
        #expect(kinds == [.onPace])
    }

    @Test func noAlertsDuringWarmup() {
        var engine = PaceEngine(goal: goal)
        var alerts: [PaceAlert] = []
        // Badly off pace, but only 25 s of data (< 30 s warm-up) → silence.
        for sample in steadySamples(paceSecPerMile: 900, duration: 25) {
            if let alert = engine.addSample(sample) { alerts.append(alert) }
        }
        #expect(alerts.isEmpty)
        #expect(engine.currentPaceSecPerMile == nil)
    }

    @Test func projectedFinishTracksReality() {
        var engine = PaceEngine(goal: goal)
        // 10:00/mi steady → true finish = 3.10686 × 600 ≈ 1864 s
        for sample in steadySamples(paceSecPerMile: 600, duration: 600) {
            _ = engine.addSample(sample)
        }
        #expect(abs(engine.projectedFinish! - 3.10686 * 600) < 15)
    }
}
