# Fitness Tracker

Personal iPhone + Apple Watch fitness app. Two sections:

- **Lift** — build workout templates, log lbs × reps per exercise (prefilled from your
  last session), and see a muscle-group heatmap of what you worked at the end.
- **Run** — pick a distance + goal time (5k, 10k, half, …) and get live pace coaching
  on the watch: haptic alerts when you drift off the pace needed to hit your goal.

## How this repo builds (no Mac required day-to-day)

| Step | Where | How |
|---|---|---|
| Core logic + tests | Linux (or any OS) | `Packages/FitnessCore` is pure Swift — `swift test` runs natively or via `podman run --rm -v "$PWD/Packages/FitnessCore:/src" -w /src docker.io/library/swift:6.1 swift test` |
| App build | GitHub Actions macOS runner | XcodeGen generates the Xcode project from `App/project.yml`, `xcodebuild` produces an **unsigned** `.ipa` artifact |
| Install on iPhone | AltStore | Download the `.ipa` artifact, install via AltStore (AltServer on Windows signs it with a free Apple ID and auto-refreshes the 7-day expiry) |

The Xcode project file is never committed — it is generated in CI from `App/project.yml`.

## Layout

```
Packages/FitnessCore/   # platform-agnostic models, pace engine, muscle mapping (Linux-testable)
App/                    # thin SwiftUI shell (iOS target; watchOS target arrives at milestone M4)
.github/workflows/      # test-core (Linux) + build-ipa (macOS)
```

## Roadmap

M0 pipeline bootstrap → M1 FitnessCore → M2 strength MVP → M3 muscle heatmap →
M4 watch run tracker (requires paid Apple Developer account *or* weekly Mac deploys —
decision deferred until then) → M5 sync & polish.
