import SwiftUI
import FitnessCore

struct HistoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            if model.repository.sessions.isEmpty {
                Text("No workouts logged yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(model.repository.sessionsByDate) { session in
                NavigationLink {
                    SessionDetailView(session: session)
                } label: {
                    VStack(alignment: .leading) {
                        Text(sessionTitle(session))
                        Text(session.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        model.mutate { $0.deleteSession(id: session.id) }
                    }
                }
            }
        }
        .navigationTitle("History")
    }

    private func sessionTitle(_ session: WorkoutSession) -> String {
        session.templateID
            .flatMap { id in model.repository.templates.first { $0.id == id }?.name }
            ?? "Workout"
    }
}

struct SessionDetailView: View {
    @Environment(AppModel.self) private var model
    let session: WorkoutSession

    @State private var showingMuscles = false

    var body: some View {
        List {
            ForEach(session.performances, id: \.exerciseID) { performance in
                Section(model.repository.exercise(id: performance.exerciseID)?.name ?? "Exercise") {
                    ForEach(Array(performance.sets.enumerated()), id: \.offset) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.weightLbs, format: .number) lbs × \(set.reps)")
                        }
                    }
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showingMuscles = true
            } label: {
                Label("Muscles", systemImage: "figure.arms.open")
            }
        }
        .sheet(isPresented: $showingMuscles) {
            NavigationStack {
                MuscleBreakdownView(session: session)
                    .navigationTitle("Muscles Worked")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
