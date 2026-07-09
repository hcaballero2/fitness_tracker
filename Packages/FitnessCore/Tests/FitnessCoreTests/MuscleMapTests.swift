import Foundation
import Testing
@testable import FitnessCore

@Suite("MuscleMap")
struct MuscleMapTests {
    let bench = ExerciseCatalog.named("Bench Press")!

    @Test func primaryCountsFullSecondaryCountsHalf() {
        // 4 sets of bench: chest 4.0 (primary), front delts + triceps 2.0 (secondary).
        let performances = [ExercisePerformance(
            exerciseID: bench.id,
            sets: Array(repeating: SetEntry(weightLbs: 135, reps: 8), count: 4)
        )]
        let scores = MuscleMap.volumeScores(performances: performances, catalog: ExerciseCatalog.byID)
        #expect(scores[.chest] == 4.0)
        #expect(scores[.frontDelts] == 2.0)
        #expect(scores[.triceps] == 2.0)
        #expect(scores[.quads] == nil)
    }

    @Test func normalizedScoresPeakAtOne() {
        let squat = ExerciseCatalog.named("Back Squat")!
        let performances = [
            ExercisePerformance(exerciseID: bench.id, sets: Array(repeating: SetEntry(weightLbs: 135, reps: 8), count: 3)),
            ExercisePerformance(exerciseID: squat.id, sets: Array(repeating: SetEntry(weightLbs: 225, reps: 5), count: 5)),
        ]
        let scores = MuscleMap.normalizedScores(performances: performances, catalog: ExerciseCatalog.byID)
        #expect(scores.values.max() == 1.0)
        #expect(scores.values.allSatisfy { $0 > 0 && $0 <= 1.0 })
    }

    @Test func unknownExerciseIsIgnored() {
        let performances = [ExercisePerformance(
            exerciseID: UUID(),
            sets: [SetEntry(weightLbs: 100, reps: 10)]
        )]
        #expect(MuscleMap.volumeScores(performances: performances, catalog: ExerciseCatalog.byID).isEmpty)
    }

    @Test func catalogHasStableIDsAndNoDuplicates() {
        // Stable ID: same name → same ID across processes.
        #expect(ExerciseCatalog.stableID(for: "Bench Press") == bench.id)
        // No two exercises collide.
        #expect(Set(ExerciseCatalog.all.map(\.id)).count == ExerciseCatalog.all.count)
        // Every exercise maps at least one primary muscle.
        #expect(ExerciseCatalog.all.allSatisfy { !$0.primaryMuscles.isEmpty })
    }
}
