import SwiftUI
import FitnessCore

struct RootView: View {
    var body: some View {
        TabView {
            LiftPlaceholderView()
                .tabItem { Label("Lift", systemImage: "dumbbell") }
            RunPlaceholderView()
                .tabItem { Label("Run", systemImage: "figure.run") }
        }
    }
}

/// M0 placeholder — replaced by the template builder + session logger in M2.
struct LiftPlaceholderView: View {
    var body: some View {
        NavigationStack {
            List(ExerciseCatalog.all.sorted(by: { $0.name < $1.name })) { exercise in
                VStack(alignment: .leading) {
                    Text(exercise.name)
                    Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Exercises")
        }
    }
}

/// M0 placeholder — proves FitnessCore pace math runs on-device; replaced in M4.
struct RunPlaceholderView: View {
    private let goal = RunGoal(distance: .fiveK, targetTime: 30 * 60)

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text(goal.distance.displayName)
                    .font(.largeTitle.bold())
                Text("Goal: \(PaceFormatter.timeString(goal.targetTime))")
                Text("Required pace: \(PaceFormatter.paceString(secPerMile: goal.requiredPaceSecPerMile))")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Run")
        }
    }
}
