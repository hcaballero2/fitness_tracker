import SwiftUI
import FitnessCore

/// App-wide state: owns the repository and persists a snapshot after
/// every mutation (write-through to the JSON file store).
@Observable @MainActor
final class AppModel {
    private(set) var repository = WorkoutRepository()
    private(set) var isLoaded = false
    var lastError: String?

    private var store: FileDataStore?

    func loadIfNeeded() async {
        guard !isLoaded else { return }
        do {
            let store = FileDataStore(fileURL: try FileDataStore.defaultURL())
            self.store = store
            repository = WorkoutRepository(archive: try await store.load())
            isLoaded = true
        } catch {
            lastError = "Failed to load data: \(error.localizedDescription)"
        }
    }

    /// Apply a mutation and persist the result.
    func mutate(_ change: (inout WorkoutRepository) -> Void) {
        change(&repository)
        persist()
    }

    private func persist() {
        guard let store else { return }
        let archive = repository.archive(exportedAt: Date())
        Task {
            do {
                try await store.save(archive)
            } catch {
                lastError = "Failed to save: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Export / import

    func exportJSON() throws -> Data {
        try repository.archive(exportedAt: Date()).jsonData()
    }

    func importJSON(_ data: Data) throws {
        let archive = try DataArchive.from(jsonData: data)
        mutate { $0.replaceAll(with: archive) }
    }
}
