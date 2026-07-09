import Foundation

/// In-memory source of truth for all user data. Pure value type — every
/// mutation is synchronous and testable on Linux; the app persists snapshots
/// via `FileDataStore` after each change.
public struct WorkoutRepository: Sendable {
    public private(set) var customExercises: [ExerciseDefinition]
    public private(set) var templates: [WorkoutTemplate]
    public private(set) var sessions: [WorkoutSession]

    public init(archive: DataArchive = DataArchive(exportedAt: .distantPast)) {
        self.customExercises = archive.customExercises
        self.templates = archive.templates
        self.sessions = archive.sessions
    }

    /// Snapshot for persistence or export.
    public func archive(exportedAt: Date) -> DataArchive {
        DataArchive(
            exportedAt: exportedAt,
            customExercises: customExercises,
            templates: templates,
            sessions: sessions
        )
    }

    // MARK: - Exercises

    /// Seeded catalog plus user-created exercises, sorted by name.
    public var allExercises: [ExerciseDefinition] {
        (ExerciseCatalog.all + customExercises).sorted { $0.name < $1.name }
    }

    /// Lookup across catalog and custom exercises.
    public func exercise(id: UUID) -> ExerciseDefinition? {
        ExerciseCatalog.byID[id] ?? customExercises.first { $0.id == id }
    }

    /// Combined lookup table (used by MuscleMap scoring).
    public var exercisesByID: [UUID: ExerciseDefinition] {
        var table = ExerciseCatalog.byID
        for exercise in customExercises { table[exercise.id] = exercise }
        return table
    }

    public mutating func addCustomExercise(_ exercise: ExerciseDefinition) {
        customExercises.append(exercise)
    }

    // MARK: - Templates

    public mutating func save(template: WorkoutTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }

    public mutating func deleteTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        // Sessions keep their history; templateID simply dangles → resolved as "Workout".
    }

    // MARK: - Sessions

    /// Record a finished session, dropping empty sets/exercises.
    public mutating func record(session: WorkoutSession) {
        var cleaned = session
        cleaned.performances = session.performances
            .map { performance in
                var p = performance
                p.sets = performance.sets.filter { $0.reps > 0 }
                return p
            }
            .filter { !$0.sets.isEmpty }
        guard !cleaned.performances.isEmpty else { return }
        sessions.append(cleaned)
    }

    public mutating func deleteSession(id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    /// Sessions newest-first for history display.
    public var sessionsByDate: [WorkoutSession] {
        sessions.sorted { $0.date > $1.date }
    }

    // MARK: - Prefill

    /// Sets to prefill when starting `exerciseID`, from its most recent performance.
    public func prefillSets(for exerciseID: UUID) -> [SetEntry]? {
        WorkoutHistory.lastSets(for: exerciseID, in: sessions)
    }

    /// Build a draft session from a template, prefilled from history.
    /// Exercises never performed start with one empty set.
    public func draftSession(from template: WorkoutTemplate, date: Date) -> WorkoutSession {
        WorkoutSession(
            templateID: template.id,
            date: date,
            performances: template.exerciseIDs.map { exerciseID in
                ExercisePerformance(
                    exerciseID: exerciseID,
                    sets: prefillSets(for: exerciseID) ?? [SetEntry(weightLbs: 0, reps: 0)]
                )
            }
        )
    }

    // MARK: - Import

    /// Replace all data with an imported archive.
    public mutating func replaceAll(with archive: DataArchive) {
        customExercises = archive.customExercises
        templates = archive.templates
        sessions = archive.sessions
    }
}
