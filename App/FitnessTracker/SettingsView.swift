import SwiftUI
import UniformTypeIdentifiers
import FitnessCore

/// Export/import of all data as JSON — the safety net against sideload
/// reinstalls, and a manual way to move data between devices.
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    @State private var exportDocument: JSONDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Data") {
                    Button {
                        do {
                            exportDocument = JSONDocument(data: try model.exportJSON())
                            showingExporter = true
                        } catch {
                            statusMessage = "Export failed: \(error.localizedDescription)"
                        }
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Import Data (replaces everything)", systemImage: "square.and.arrow.down")
                    }
                }

                Section("Stats") {
                    LabeledContent("Workouts logged", value: "\(model.repository.sessions.count)")
                    LabeledContent("Templates", value: "\(model.repository.templates.count)")
                    LabeledContent("Custom exercises", value: "\(model.repository.customExercises.count)")
                }

                if let statusMessage {
                    Section { Text(statusMessage).foregroundStyle(.secondary) }
                }
                if let error = model.lastError {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "fitness-export-\(Date().formatted(.iso8601.year().month().day()))"
            ) { result in
                if case .success = result { statusMessage = "Exported." }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    do {
                        let accessing = url.startAccessingSecurityScopedResource()
                        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                        try model.importJSON(Data(contentsOf: url))
                        statusMessage = "Imported \(model.repository.sessions.count) workouts."
                    } catch {
                        statusMessage = "Import failed: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    statusMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

/// Minimal FileDocument wrapper for JSON data.
struct JSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
