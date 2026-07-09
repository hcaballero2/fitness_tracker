import SwiftUI
import FitnessCore

struct RootView: View {
    @State private var model = AppModel()

    var body: some View {
        TabView {
            LiftHomeView()
                .tabItem { Label("Lift", systemImage: "dumbbell") }
            RunPlaceholderView()
                .tabItem { Label("Run", systemImage: "figure.run") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .environment(model)
        .task { await model.loadIfNeeded() }
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
                Text("Live pace coaching arrives with the watch app (M4).")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
            .navigationTitle("Run")
        }
    }
}
