import Foundation
import Testing
@testable import FitnessCore

@Suite("Workout prefill")
struct PrefillTests {
    let bench = ExerciseCatalog.named("Bench Press")!
    let squat = ExerciseCatalog.named("Back Squat")!

    @Test func prefillUsesMostRecentSession() {
        let old = WorkoutSession(
            date: Date(timeIntervalSince1970: 1_000),
            performances: [ExercisePerformance(
                exerciseID: bench.id,
                sets: [SetEntry(weightLbs: 135, reps: 10)]
            )]
        )
        let recent = WorkoutSession(
            date: Date(timeIntervalSince1970: 2_000),
            performances: [ExercisePerformance(
                exerciseID: bench.id,
                sets: [SetEntry(weightLbs: 145, reps: 8), SetEntry(weightLbs: 145, reps: 7)]
            )]
        )
        let sets = WorkoutHistory.lastSets(for: bench.id, in: [old, recent])
        #expect(sets == [SetEntry(weightLbs: 145, reps: 8), SetEntry(weightLbs: 145, reps: 7)])
    }

    @Test func prefillSkipsSessionsWithoutTheExercise() {
        let squatDay = WorkoutSession(
            date: Date(timeIntervalSince1970: 3_000),
            performances: [ExercisePerformance(
                exerciseID: squat.id,
                sets: [SetEntry(weightLbs: 225, reps: 5)]
            )]
        )
        let benchDay = WorkoutSession(
            date: Date(timeIntervalSince1970: 2_000),
            performances: [ExercisePerformance(
                exerciseID: bench.id,
                sets: [SetEntry(weightLbs: 135, reps: 10)]
            )]
        )
        let sets = WorkoutHistory.lastSets(for: bench.id, in: [squatDay, benchDay])
        #expect(sets == [SetEntry(weightLbs: 135, reps: 10)])
    }

    @Test func prefillNilForNeverPerformedExercise() {
        #expect(WorkoutHistory.lastSets(for: bench.id, in: []) == nil)
    }
}

@Suite("DataArchive")
struct DataArchiveTests {
    @Test func roundTripsThroughJSON() throws {
        let bench = ExerciseCatalog.named("Bench Press")!
        let archive = DataArchive(
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            templates: [WorkoutTemplate(name: "Push Day", exerciseIDs: [bench.id])],
            sessions: [WorkoutSession(
                date: Date(timeIntervalSince1970: 1_750_000_000),
                performances: [ExercisePerformance(
                    exerciseID: bench.id,
                    sets: [SetEntry(weightLbs: 145, reps: 8)]
                )]
            )]
        )
        let restored = try DataArchive.from(jsonData: archive.jsonData())
        #expect(restored.templates == archive.templates)
        #expect(restored.sessions == archive.sessions)
    }
}
