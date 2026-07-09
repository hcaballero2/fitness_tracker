import Foundation
import Testing
@testable import FitnessCore

@Suite("WorkoutRepository")
struct RepositoryTests {
    let bench = ExerciseCatalog.named("Bench Press")!
    let squat = ExerciseCatalog.named("Back Squat")!

    @Test func templateSaveIsUpsert() {
        var repo = WorkoutRepository()
        var template = WorkoutTemplate(name: "Push", exerciseIDs: [bench.id])
        repo.save(template: template)
        template.name = "Push Day"
        repo.save(template: template)
        #expect(repo.templates.count == 1)
        #expect(repo.templates[0].name == "Push Day")
    }

    @Test func draftPrefillsFromLastSession() {
        var repo = WorkoutRepository()
        let template = WorkoutTemplate(name: "Push", exerciseIDs: [bench.id, squat.id])
        repo.save(template: template)
        repo.record(session: WorkoutSession(
            templateID: template.id,
            date: Date(timeIntervalSince1970: 1_000),
            performances: [ExercisePerformance(
                exerciseID: bench.id,
                sets: [SetEntry(weightLbs: 145, reps: 8)]
            )]
        ))

        let draft = repo.draftSession(from: template, date: Date(timeIntervalSince1970: 2_000))
        // Bench: prefilled from history. Squat: never performed → one empty set.
        #expect(draft.performances[0].sets == [SetEntry(weightLbs: 145, reps: 8)])
        #expect(draft.performances[1].sets == [SetEntry(weightLbs: 0, reps: 0)])
    }

    @Test func recordDropsEmptySetsAndExercises() {
        var repo = WorkoutRepository()
        repo.record(session: WorkoutSession(
            date: Date(timeIntervalSince1970: 1_000),
            performances: [
                ExercisePerformance(exerciseID: bench.id, sets: [
                    SetEntry(weightLbs: 135, reps: 10),
                    SetEntry(weightLbs: 0, reps: 0), // untouched row
                ]),
                ExercisePerformance(exerciseID: squat.id, sets: [
                    SetEntry(weightLbs: 0, reps: 0), // skipped exercise
                ]),
            ]
        ))
        #expect(repo.sessions.count == 1)
        #expect(repo.sessions[0].performances.count == 1)
        #expect(repo.sessions[0].performances[0].sets.count == 1)
    }

    @Test func fullyEmptySessionIsNotRecorded() {
        var repo = WorkoutRepository()
        repo.record(session: WorkoutSession(
            date: Date(timeIntervalSince1970: 1_000),
            performances: [ExercisePerformance(exerciseID: bench.id, sets: [SetEntry(weightLbs: 0, reps: 0)])]
        ))
        #expect(repo.sessions.isEmpty)
    }

    @Test func customExercisesAppearInLookupAndList() {
        var repo = WorkoutRepository()
        let cableRow = ExerciseDefinition(name: "Meadows Row", primaryMuscles: [.lats], secondaryMuscles: [.biceps])
        repo.addCustomExercise(cableRow)
        #expect(repo.exercise(id: cableRow.id) == cableRow)
        #expect(repo.allExercises.contains(cableRow))
        #expect(repo.exercisesByID[cableRow.id] == cableRow)
    }

    @Test func archiveRoundTripPreservesEverything() {
        var repo = WorkoutRepository()
        let custom = ExerciseDefinition(name: "Meadows Row", primaryMuscles: [.lats])
        repo.addCustomExercise(custom)
        repo.save(template: WorkoutTemplate(name: "Pull", exerciseIDs: [custom.id]))
        repo.record(session: WorkoutSession(
            date: Date(timeIntervalSince1970: 5_000),
            performances: [ExercisePerformance(exerciseID: custom.id, sets: [SetEntry(weightLbs: 90, reps: 12)])]
        ))

        let restored = WorkoutRepository(archive: repo.archive(exportedAt: Date(timeIntervalSince1970: 6_000)))
        #expect(restored.customExercises == repo.customExercises)
        #expect(restored.templates == repo.templates)
        #expect(restored.sessions == repo.sessions)
    }
}

@Suite("FileDataStore")
struct FileDataStoreTests {
    @Test func loadReturnsEmptyArchiveWhenFileMissing() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")
        let store = FileDataStore(fileURL: url)
        let archive = try await store.load()
        #expect(archive.sessions.isEmpty && archive.templates.isEmpty)
    }

    @Test func saveThenLoadRoundTrips() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("store-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let bench = ExerciseCatalog.named("Bench Press")!
        let archive = DataArchive(
            exportedAt: Date(timeIntervalSince1970: 1_750_000_000),
            templates: [WorkoutTemplate(name: "Push", exerciseIDs: [bench.id])],
            sessions: [WorkoutSession(
                date: Date(timeIntervalSince1970: 1_750_000_000),
                performances: [ExercisePerformance(exerciseID: bench.id, sets: [SetEntry(weightLbs: 145, reps: 8)])]
            )]
        )
        let store = FileDataStore(fileURL: url)
        try await store.save(archive)
        let loaded = try await store.load()
        #expect(loaded.templates == archive.templates)
        #expect(loaded.sessions == archive.sessions)
    }
}
