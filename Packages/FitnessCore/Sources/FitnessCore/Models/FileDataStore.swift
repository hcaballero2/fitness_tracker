import Foundation

/// Persists a `DataArchive` to a JSON file with atomic writes.
/// The on-disk format IS the export format — backup is a file copy.
public actor FileDataStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    /// Default store location inside Application Support.
    public static func defaultURL() throws -> URL {
        let dir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return dir.appendingPathComponent("fitness-data.json")
    }

    /// Load the archive; returns an empty one when no file exists yet.
    public func load() throws -> DataArchive {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return DataArchive(exportedAt: .distantPast)
        }
        return try DataArchive.from(jsonData: Data(contentsOf: fileURL))
    }

    public func save(_ archive: DataArchive) throws {
        try archive.jsonData().write(to: fileURL, options: .atomic)
    }
}
