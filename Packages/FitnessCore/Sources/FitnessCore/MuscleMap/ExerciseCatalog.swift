import Foundation

/// Seeded catalog of common exercises with muscle mappings.
///
/// IDs are stable (derived from the exercise name) so that logged history
/// keeps pointing at the right exercise across app updates. User-created
/// exercises get random UUIDs and live alongside these.
public enum ExerciseCatalog {
    /// Deterministic UUID from an exercise name (stable across launches/updates).
    static func stableID(for name: String) -> UUID {
        // FNV-1a over the lowercased name, expanded to 16 bytes.
        var hash1: UInt64 = 0xcbf29ce484222325
        for byte in name.lowercased().utf8 {
            hash1 ^= UInt64(byte)
            hash1 = hash1 &* 0x100000001b3
        }
        var hash2: UInt64 = 0x9e3779b97f4a7c15
        for byte in name.lowercased().utf8.reversed() {
            hash2 ^= UInt64(byte)
            hash2 = hash2 &* 0x100000001b3
        }
        var bytes = [UInt8]()
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8((hash1 >> shift) & 0xff))
        }
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8((hash2 >> shift) & 0xff))
        }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }

    private static func make(
        _ name: String,
        primary: [MuscleGroup],
        secondary: [MuscleGroup] = []
    ) -> ExerciseDefinition {
        ExerciseDefinition(
            id: stableID(for: name),
            name: name,
            primaryMuscles: primary,
            secondaryMuscles: secondary
        )
    }

    public static let all: [ExerciseDefinition] = [
        // Chest
        make("Bench Press", primary: [.chest], secondary: [.frontDelts, .triceps]),
        make("Incline Bench Press", primary: [.chest, .frontDelts], secondary: [.triceps]),
        make("Dumbbell Bench Press", primary: [.chest], secondary: [.frontDelts, .triceps]),
        make("Incline Dumbbell Press", primary: [.chest, .frontDelts], secondary: [.triceps]),
        make("Chest Fly", primary: [.chest], secondary: [.frontDelts]),
        make("Cable Crossover", primary: [.chest], secondary: [.frontDelts]),
        make("Push-Up", primary: [.chest], secondary: [.frontDelts, .triceps, .abs]),
        make("Dip", primary: [.chest, .triceps], secondary: [.frontDelts]),

        // Back
        make("Deadlift", primary: [.lowerBack, .glutes, .hamstrings], secondary: [.traps, .lats, .forearms, .quads]),
        make("Pull-Up", primary: [.lats], secondary: [.biceps, .upperBack, .forearms]),
        make("Chin-Up", primary: [.lats, .biceps], secondary: [.upperBack, .forearms]),
        make("Lat Pulldown", primary: [.lats], secondary: [.biceps, .upperBack]),
        make("Barbell Row", primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts, .lowerBack]),
        make("Dumbbell Row", primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts]),
        make("Seated Cable Row", primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts]),
        make("T-Bar Row", primary: [.upperBack, .lats], secondary: [.biceps, .rearDelts]),
        make("Face Pull", primary: [.rearDelts, .upperBack], secondary: [.traps]),
        make("Back Extension", primary: [.lowerBack], secondary: [.glutes, .hamstrings]),
        make("Shrug", primary: [.traps], secondary: [.forearms]),

        // Shoulders
        make("Overhead Press", primary: [.frontDelts, .sideDelts], secondary: [.triceps, .traps]),
        make("Dumbbell Shoulder Press", primary: [.frontDelts, .sideDelts], secondary: [.triceps]),
        make("Arnold Press", primary: [.frontDelts, .sideDelts], secondary: [.triceps]),
        make("Lateral Raise", primary: [.sideDelts]),
        make("Front Raise", primary: [.frontDelts]),
        make("Reverse Fly", primary: [.rearDelts], secondary: [.upperBack]),
        make("Upright Row", primary: [.sideDelts, .traps], secondary: [.biceps]),

        // Arms
        make("Barbell Curl", primary: [.biceps], secondary: [.forearms]),
        make("Dumbbell Curl", primary: [.biceps], secondary: [.forearms]),
        make("Hammer Curl", primary: [.biceps, .forearms]),
        make("Preacher Curl", primary: [.biceps]),
        make("Cable Curl", primary: [.biceps], secondary: [.forearms]),
        make("Tricep Pushdown", primary: [.triceps]),
        make("Skull Crusher", primary: [.triceps]),
        make("Overhead Tricep Extension", primary: [.triceps]),
        make("Close-Grip Bench Press", primary: [.triceps, .chest], secondary: [.frontDelts]),
        make("Wrist Curl", primary: [.forearms]),

        // Legs
        make("Back Squat", primary: [.quads, .glutes], secondary: [.hamstrings, .lowerBack, .abs, .adductors]),
        make("Front Squat", primary: [.quads], secondary: [.glutes, .abs, .upperBack]),
        make("Goblet Squat", primary: [.quads, .glutes], secondary: [.abs]),
        make("Leg Press", primary: [.quads, .glutes], secondary: [.hamstrings, .adductors]),
        make("Romanian Deadlift", primary: [.hamstrings, .glutes], secondary: [.lowerBack, .forearms]),
        make("Leg Curl", primary: [.hamstrings]),
        make("Leg Extension", primary: [.quads]),
        make("Walking Lunge", primary: [.quads, .glutes], secondary: [.hamstrings, .abs]),
        make("Bulgarian Split Squat", primary: [.quads, .glutes], secondary: [.hamstrings, .adductors]),
        make("Hip Thrust", primary: [.glutes], secondary: [.hamstrings]),
        make("Calf Raise", primary: [.calves]),
        make("Seated Calf Raise", primary: [.calves]),
        make("Hip Adduction", primary: [.adductors]),

        // Core
        make("Plank", primary: [.abs], secondary: [.obliques, .lowerBack]),
        make("Crunch", primary: [.abs]),
        make("Hanging Leg Raise", primary: [.abs, .hipFlexors], secondary: [.obliques, .forearms]),
        make("Russian Twist", primary: [.obliques], secondary: [.abs]),
        make("Cable Woodchopper", primary: [.obliques], secondary: [.abs]),
        make("Ab Wheel Rollout", primary: [.abs], secondary: [.obliques, .lats]),
    ]

    /// Lookup table keyed by exercise ID, for scoring and display.
    public static let byID: [UUID: ExerciseDefinition] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    /// Case-insensitive name lookup, for tests and import/matching.
    public static func named(_ name: String) -> ExerciseDefinition? {
        byID[stableID(for: name)]
    }
}
