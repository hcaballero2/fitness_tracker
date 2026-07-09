import SwiftUI
import FitnessCore

/// Create or edit a workout template: name it, pick and order exercises.
struct TemplateEditorView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State var template: WorkoutTemplate
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Workout name (e.g. Push Day)", text: $template.name)
                }
                Section("Exercises") {
                    ForEach(template.exerciseIDs, id: \.self) { id in
                        Text(model.repository.exercise(id: id)?.name ?? "Unknown")
                    }
                    .onDelete { template.exerciseIDs.remove(atOffsets: $0) }
                    .onMove { template.exerciseIDs.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                }
            }
            .navigationTitle(template.name.isEmpty ? "New Workout" : template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.mutate { $0.save(template: template) }
                        dismiss()
                    }
                    .disabled(template.name.trimmingCharacters(in: .whitespaces).isEmpty
                              || template.exerciseIDs.isEmpty)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExercisePickerView { exercise in
                    // Rows are keyed by exercise ID, so a template holds each exercise once.
                    if !template.exerciseIDs.contains(exercise.id) {
                        template.exerciseIDs.append(exercise.id)
                    }
                }
            }
        }
    }
}
