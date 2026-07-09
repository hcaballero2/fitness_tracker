import SwiftUI
import FitnessCore

/// Searchable picker over the catalog + custom exercises, with inline
/// creation of new custom exercises.
struct ExercisePickerView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    let onPick: (ExerciseDefinition) -> Void

    @State private var search = ""
    @State private var creatingNew = false

    private var filtered: [ExerciseDefinition] {
        let all = model.repository.allExercises
        guard !search.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { exercise in
                    Button {
                        onPick(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(exercise.name)
                                .foregroundStyle(.primary)
                            Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Button {
                    creatingNew = true
                } label: {
                    Label("New Custom Exercise", systemImage: "plus")
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $creatingNew) {
                NewExerciseView { exercise in
                    model.mutate { $0.addCustomExercise(exercise) }
                    onPick(exercise)
                    dismiss()
                }
            }
        }
    }
}

/// Form for creating a custom exercise with muscle mappings.
struct NewExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (ExerciseDefinition) -> Void

    @State private var name = ""
    @State private var primary: Set<MuscleGroup> = []
    @State private var secondary: Set<MuscleGroup> = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise name", text: $name)
                }
                Section("Primary muscles (full credit)") {
                    muscleGrid(selection: $primary, excluded: secondary)
                }
                Section("Secondary muscles (half credit)") {
                    muscleGrid(selection: $secondary, excluded: primary)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(ExerciseDefinition(
                            name: name.trimmingCharacters(in: .whitespaces),
                            primaryMuscles: Array(primary),
                            secondaryMuscles: Array(secondary)
                        ))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || primary.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private func muscleGrid(selection: Binding<Set<MuscleGroup>>, excluded: Set<MuscleGroup>) -> some View {
        ForEach(MuscleGroup.allCases.filter { !excluded.contains($0) }, id: \.self) { muscle in
            Button {
                if selection.wrappedValue.contains(muscle) {
                    selection.wrappedValue.remove(muscle)
                } else {
                    selection.wrappedValue.insert(muscle)
                }
            } label: {
                HStack {
                    Text(muscle.displayName)
                        .foregroundStyle(.primary)
                    Spacer()
                    if selection.wrappedValue.contains(muscle) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
    }
}
