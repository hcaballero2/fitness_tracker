import SwiftUI
import FitnessCore

/// Live workout logging: one section per exercise, sets prefilled from the
/// last time this exercise was performed.
struct ActiveWorkoutView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State var draft: WorkoutSession
    @State private var finishedSession: WorkoutSession?
    @State private var confirmingDiscard = false

    var body: some View {
        NavigationStack {
            Form {
                ForEach($draft.performances, id: \.exerciseID) { $performance in
                    Section(model.repository.exercise(id: performance.exerciseID)?.name ?? "Exercise") {
                        ForEach(performance.sets.indices, id: \.self) { index in
                            SetRow(index: index, set: $performance.sets[index])
                        }
                        .onDelete { performance.sets.remove(atOffsets: $0) }

                        Button {
                            // New set starts as a copy of the previous one.
                            let previous = performance.sets.last ?? SetEntry(weightLbs: 0, reps: 0)
                            performance.sets.append(previous)
                        } label: {
                            Label("Add Set", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { confirmingDiscard = true }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        model.mutate { $0.record(session: draft) }
                        finishedSession = draft
                    }
                }
            }
            .confirmationDialog("Discard this workout?", isPresented: $confirmingDiscard) {
                Button("Discard Workout", role: .destructive) { dismiss() }
            }
            .sheet(item: $finishedSession) { session in
                WorkoutSummaryView(session: session) { dismiss() }
            }
        }
    }
}

/// One editable set: weight (lbs) and reps.
struct SetRow: View {
    let index: Int
    @Binding var set: SetEntry

    var body: some View {
        HStack {
            Text("Set \(index + 1)")
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            TextField("lbs", value: $set.weightLbs, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            Text("lbs ×")
                .foregroundStyle(.secondary)
            TextField("reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 48)
        }
    }
}

/// End-of-workout summary: body heatmap + per-muscle volume detail.
struct WorkoutSummaryView: View {
    let session: WorkoutSession
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            MuscleBreakdownView(session: session)
                .navigationTitle("Nice work!")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onDone() }
                    }
                }
        }
    }
}

/// Shared muscle analysis: heatmap figures + sorted volume bars.
/// Used by the end-of-workout summary and session history detail.
struct MuscleBreakdownView: View {
    @Environment(AppModel.self) private var model
    let session: WorkoutSession

    private var scores: [MuscleGroup: Double] {
        MuscleMap.normalizedScores(
            performances: session.performances,
            catalog: model.repository.exercisesByID
        )
    }

    var body: some View {
        let scores = self.scores
        List {
            Section {
                if scores.isEmpty {
                    Text("No completed sets.")
                        .foregroundStyle(.secondary)
                } else {
                    BodyHeatmapView(scores: scores)
                        .padding(.vertical, 8)
                }
            }
            if !scores.isEmpty {
                Section("Volume by muscle") {
                    ForEach(scores.sorted { $0.value > $1.value }, id: \.key) { muscle, score in
                        HStack {
                            Text(muscle.displayName)
                                .frame(width: 120, alignment: .leading)
                            ProgressView(value: score)
                                .tint(BodyHeatmapView.heat(score))
                        }
                    }
                }
            }
        }
    }
}
