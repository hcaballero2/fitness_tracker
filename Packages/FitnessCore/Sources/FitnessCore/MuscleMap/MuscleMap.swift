import Foundation

/// Scores per-muscle training volume for a workout session, powering the
/// end-of-workout body-diagram heatmap.
public enum MuscleMap {
    /// Weighting for secondary muscle involvement relative to primary (1.0).
    public static let secondaryWeight = 0.5

    /// Raw volume score per muscle group: Σ over exercises of
    /// (set count × muscle weight). Groups not trained are absent.
    public static func volumeScores(
        performances: [ExercisePerformance],
        catalog: [UUID: ExerciseDefinition]
    ) -> [MuscleGroup: Double] {
        var scores: [MuscleGroup: Double] = [:]
        for performance in performances {
            guard let exercise = catalog[performance.exerciseID] else { continue }
            let setCount = Double(performance.sets.count)
            guard setCount > 0 else { continue }
            for muscle in exercise.primaryMuscles {
                scores[muscle, default: 0] += setCount
            }
            for muscle in exercise.secondaryMuscles {
                scores[muscle, default: 0] += setCount * secondaryWeight
            }
        }
        return scores
    }

    /// Scores normalized to 0...1 (relative to the hardest-worked group),
    /// ready to drive a color ramp on the body diagram.
    public static func normalizedScores(
        performances: [ExercisePerformance],
        catalog: [UUID: ExerciseDefinition]
    ) -> [MuscleGroup: Double] {
        let raw = volumeScores(performances: performances, catalog: catalog)
        guard let maxScore = raw.values.max(), maxScore > 0 else { return [:] }
        return raw.mapValues { $0 / maxScore }
    }
}
