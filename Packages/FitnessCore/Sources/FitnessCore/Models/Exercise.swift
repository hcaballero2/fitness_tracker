import Foundation

/// A named exercise and the muscle groups it trains.
public struct ExerciseDefinition: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    /// Groups trained directly — weighted 1.0 in volume scoring.
    public var primaryMuscles: [MuscleGroup]
    /// Groups assisting — weighted 0.5 in volume scoring.
    public var secondaryMuscles: [MuscleGroup]

    public init(
        id: UUID = UUID(),
        name: String,
        primaryMuscles: [MuscleGroup],
        secondaryMuscles: [MuscleGroup] = []
    ) {
        self.id = id
        self.name = name
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
    }
}
