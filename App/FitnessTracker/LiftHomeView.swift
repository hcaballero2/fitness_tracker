import SwiftUI
import FitnessCore

struct LiftHomeView: View {
    @Environment(AppModel.self) private var model
    @State private var editingTemplate: WorkoutTemplate?
    @State private var activeDraft: WorkoutSession?

    var body: some View {
        NavigationStack {
            List {
                Section("Workouts") {
                    if model.repository.templates.isEmpty {
                        Text("Create a workout to get started.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.repository.templates) { template in
                        Button {
                            activeDraft = model.repository.draftSession(from: template, date: Date())
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(template.name)
                                        .foregroundStyle(.primary)
                                    Text(exerciseSummary(for: template))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(.tint)
                                    .font(.title2)
                            }
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                model.mutate { $0.deleteTemplate(id: template.id) }
                            }
                            Button("Edit") { editingTemplate = template }
                        }
                    }
                }

                Section {
                    NavigationLink("History") { HistoryView() }
                }
            }
            .navigationTitle("Lift")
            .toolbar {
                Button {
                    editingTemplate = WorkoutTemplate(name: "", exerciseIDs: [])
                } label: {
                    Label("New Workout", systemImage: "plus")
                }
            }
            .sheet(item: $editingTemplate) { template in
                TemplateEditorView(template: template)
            }
            .fullScreenCover(item: $activeDraft) { draft in
                ActiveWorkoutView(draft: draft)
            }
        }
    }

    private func exerciseSummary(for template: WorkoutTemplate) -> String {
        template.exerciseIDs
            .compactMap { model.repository.exercise(id: $0)?.name }
            .joined(separator: " · ")
    }
}
