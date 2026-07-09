import Foundation

/// Full export/import envelope for all user data.
///
/// Belt-and-braces against sideload/app-deletion data loss: the app can dump
/// this to a JSON file (share sheet / Files) and re-import it after a reinstall.
public struct DataArchive: Codable, Sendable {
    public var schemaVersion: Int
    public var exportedAt: Date
    /// User-created exercises (catalog exercises are re-seeded, not exported).
    public var customExercises: [ExerciseDefinition]
    public var templates: [WorkoutTemplate]
    public var sessions: [WorkoutSession]

    public init(
        schemaVersion: Int = 1,
        exportedAt: Date,
        customExercises: [ExerciseDefinition] = [],
        templates: [WorkoutTemplate] = [],
        sessions: [WorkoutSession] = []
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAt = exportedAt
        self.customExercises = customExercises
        self.templates = templates
        self.sessions = sessions
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    public static func from(jsonData: Data) throws -> DataArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(DataArchive.self, from: jsonData)
    }
}
