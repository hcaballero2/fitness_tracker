import Foundation

/// A single logged set: weight in pounds × repetitions.
public struct SetEntry: Codable, Hashable, Sendable {
    public var weightLbs: Double
    public var reps: Int

    public init(weightLbs: Double, reps: Int) {
        self.weightLbs = weightLbs
        self.reps = reps
    }
}

/// All sets performed for one exercise within one session.
public struct ExercisePerformance: Codable, Hashable, Sendable {
    public var exerciseID: UUID
    public var sets: [SetEntry]

    public init(exerciseID: UUID, sets: [SetEntry]) {
        self.exerciseID = exerciseID
        self.sets = sets
    }
}

/// A reusable workout definition: an ordered list of exercises.
public struct WorkoutTemplate: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var exerciseIDs: [UUID]

    public init(id: UUID = UUID(), name: String, exerciseIDs: [UUID]) {
        self.id = id
        self.name = name
        self.exerciseIDs = exerciseIDs
    }
}

/// One completed (or in-progress) workout.
public struct WorkoutSession: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var templateID: UUID?
    public var date: Date
    public var performances: [ExercisePerformance]

    public init(
        id: UUID = UUID(),
        templateID: UUID? = nil,
        date: Date,
        performances: [ExercisePerformance] = []
    ) {
        self.id = id
        self.templateID = templateID
        self.date = date
        self.performances = performances
    }
}

public enum WorkoutHistory {
    /// Prefill sets for an exercise from the most recent session that included it.
    /// Returns `nil` when the exercise has never been performed.
    public static func lastSets(
        for exerciseID: UUID,
        in sessions: [WorkoutSession]
    ) -> [SetEntry]? {
        sessions
            .sorted { $0.date > $1.date }
            .lazy
            .compactMap { session in
                session.performances.first { $0.exerciseID == exerciseID }?.sets
            }
            .first { !$0.isEmpty }
    }
}
