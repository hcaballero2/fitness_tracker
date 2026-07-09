/// Muscle groups used for exercise mapping and the end-of-workout heatmap.
/// Each case corresponds to a tintable region on the body diagram.
public enum MuscleGroup: String, Codable, CaseIterable, Sendable, Hashable {
    // Front
    case chest
    case frontDelts
    case sideDelts
    case biceps
    case forearms
    case abs
    case obliques
    case quads
    case hipFlexors
    case adductors

    // Back
    case traps
    case rearDelts
    case lats
    case upperBack
    case lowerBack
    case triceps
    case glutes
    case hamstrings
    case calves

    /// Whether this group is drawn on the front or back body diagram.
    public var side: BodySide {
        switch self {
        case .chest, .frontDelts, .sideDelts, .biceps, .forearms,
             .abs, .obliques, .quads, .hipFlexors, .adductors:
            return .front
        case .traps, .rearDelts, .lats, .upperBack, .lowerBack,
             .triceps, .glutes, .hamstrings, .calves:
            return .back
        }
    }

    public var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .frontDelts: return "Front Delts"
        case .sideDelts: return "Side Delts"
        case .biceps: return "Biceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .obliques: return "Obliques"
        case .quads: return "Quads"
        case .hipFlexors: return "Hip Flexors"
        case .adductors: return "Adductors"
        case .traps: return "Traps"
        case .rearDelts: return "Rear Delts"
        case .lats: return "Lats"
        case .upperBack: return "Upper Back"
        case .lowerBack: return "Lower Back"
        case .triceps: return "Triceps"
        case .glutes: return "Glutes"
        case .hamstrings: return "Hamstrings"
        case .calves: return "Calves"
        }
    }
}

public enum BodySide: String, Codable, Sendable {
    case front
    case back
}
