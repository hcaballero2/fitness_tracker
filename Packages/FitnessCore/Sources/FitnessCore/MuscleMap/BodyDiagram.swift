import Foundation

/// Layout data for the stylized body heatmap: each muscle group maps to one
/// or more tintable regions on the front or back figure, positioned in a
/// normalized 0...1 coordinate space (origin top-left, figure centered at x=0.5).
///
/// Rendering (colors, silhouette, scaling) lives in the app; keeping the
/// geometry here lets Linux tests guarantee full muscle coverage.
public struct BodyRegion: Sendable, Equatable {
    public enum ShapeKind: Sendable, Equatable {
        case ellipse
        case capsule
        case roundedRect
    }

    public let muscle: MuscleGroup
    public let shape: ShapeKind
    /// Normalized frame: (origin.x, origin.y, width, height), all in 0...1.
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    init(_ muscle: MuscleGroup, _ shape: ShapeKind,
         centerX: Double, centerY: Double, width: Double, height: Double) {
        self.muscle = muscle
        self.shape = shape
        self.x = centerX - width / 2
        self.y = centerY - height / 2
        self.width = width
        self.height = height
    }

    /// Mirror image across the figure's vertical centerline (for bilateral pairs).
    var mirrored: BodyRegion {
        BodyRegion(muscle, shape,
                   centerX: 1.0 - (x + width / 2), centerY: y + height / 2,
                   width: width, height: height)
    }
}

public enum BodyDiagram {
    /// Bilateral pair helper.
    private static func pair(
        _ muscle: MuscleGroup, _ shape: BodyRegion.ShapeKind,
        centerX: Double, centerY: Double, width: Double, height: Double
    ) -> [BodyRegion] {
        let region = BodyRegion(muscle, shape, centerX: centerX, centerY: centerY,
                                width: width, height: height)
        return [region, region.mirrored]
    }

    public static let frontRegions: [BodyRegion] =
        pair(.frontDelts, .ellipse, centerX: 0.325, centerY: 0.165, width: 0.09, height: 0.055)
        + pair(.sideDelts, .ellipse, centerX: 0.255, centerY: 0.175, width: 0.055, height: 0.07)
        + pair(.chest, .roundedRect, centerX: 0.415, centerY: 0.225, width: 0.145, height: 0.09)
        + pair(.biceps, .capsule, centerX: 0.28, centerY: 0.305, width: 0.075, height: 0.11)
        + pair(.forearms, .capsule, centerX: 0.245, centerY: 0.43, width: 0.065, height: 0.12)
        + [BodyRegion(.abs, .roundedRect, centerX: 0.5, centerY: 0.345, width: 0.13, height: 0.16)]
        + pair(.obliques, .roundedRect, centerX: 0.405, centerY: 0.345, width: 0.05, height: 0.14)
        + pair(.hipFlexors, .ellipse, centerX: 0.445, centerY: 0.455, width: 0.07, height: 0.05)
        + pair(.adductors, .capsule, centerX: 0.46, centerY: 0.565, width: 0.055, height: 0.12)
        + pair(.quads, .capsule, centerX: 0.415, centerY: 0.585, width: 0.085, height: 0.17)

    public static let backRegions: [BodyRegion] =
        [BodyRegion(.traps, .roundedRect, centerX: 0.5, centerY: 0.145, width: 0.20, height: 0.06)]
        + pair(.rearDelts, .ellipse, centerX: 0.30, centerY: 0.17, width: 0.075, height: 0.06)
        + [BodyRegion(.upperBack, .roundedRect, centerX: 0.5, centerY: 0.225, width: 0.24, height: 0.09)]
        + pair(.lats, .roundedRect, centerX: 0.42, centerY: 0.315, width: 0.09, height: 0.13)
        + [BodyRegion(.lowerBack, .roundedRect, centerX: 0.5, centerY: 0.40, width: 0.14, height: 0.08)]
        + pair(.triceps, .capsule, centerX: 0.27, centerY: 0.305, width: 0.07, height: 0.11)
        + pair(.glutes, .ellipse, centerX: 0.455, centerY: 0.48, width: 0.09, height: 0.09)
        + pair(.hamstrings, .capsule, centerX: 0.42, centerY: 0.60, width: 0.085, height: 0.16)
        + pair(.calves, .capsule, centerX: 0.43, centerY: 0.76, width: 0.075, height: 0.13)

    public static func regions(for side: BodySide) -> [BodyRegion] {
        side == .front ? frontRegions : backRegions
    }

    /// Silhouette pieces (non-tintable context: head, torso, limbs) shared by
    /// both figures, as normalized frames. Same shape vocabulary as regions.
    public static let silhouette: [BodyRegion] = {
        // Muscle field is unused for silhouette pieces; .abs is a placeholder.
        func piece(_ shape: BodyRegion.ShapeKind, centerX: Double, centerY: Double,
                   width: Double, height: Double) -> BodyRegion {
            BodyRegion(.abs, shape, centerX: centerX, centerY: centerY, width: width, height: height)
        }
        return [
            piece(.ellipse, centerX: 0.5, centerY: 0.06, width: 0.10, height: 0.10),   // head
            piece(.roundedRect, centerX: 0.5, centerY: 0.30, width: 0.38, height: 0.30), // torso
            piece(.roundedRect, centerX: 0.5, centerY: 0.475, width: 0.32, height: 0.09), // pelvis
            piece(.capsule, centerX: 0.265, centerY: 0.36, width: 0.10, height: 0.32),  // arm L
            piece(.capsule, centerX: 0.735, centerY: 0.36, width: 0.10, height: 0.32),  // arm R
            piece(.capsule, centerX: 0.43, centerY: 0.67, width: 0.11, height: 0.45),   // leg L
            piece(.capsule, centerX: 0.57, centerY: 0.67, width: 0.11, height: 0.45),   // leg R
        ]
    }()
}
