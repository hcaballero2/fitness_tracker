import SwiftUI
import FitnessCore

/// Front + back body figures with muscle regions tinted by normalized
/// training volume (0 = untrained gray, 1 = hottest red).
struct BodyHeatmapView: View {
    let scores: [MuscleGroup: Double]

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                BodyFigureView(side: .front, scores: scores)
                BodyFigureView(side: .back, scores: scores)
            }
            .frame(height: 320)

            HStack(spacing: 24) {
                Text("Front").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Text("Back").font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }

            // Legend: cool → hot ramp.
            HStack(spacing: 6) {
                Text("Light").font(.caption2).foregroundStyle(.secondary)
                LinearGradient(
                    colors: [Self.heat(0.05), Self.heat(0.5), Self.heat(1.0)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 8)
                .clipShape(Capsule())
                Text("Heavy").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
        }
    }

    /// Shared color ramp: yellow (light work) → red (heaviest muscle).
    static func heat(_ score: Double) -> Color {
        Color(hue: 0.13 * (1 - score), saturation: 0.9, brightness: 0.95)
    }
}

/// One figure (front or back), drawn in a Canvas from normalized region frames.
struct BodyFigureView: View {
    let side: BodySide
    let scores: [MuscleGroup: Double]

    var body: some View {
        Canvas { context, size in
            // Keep the figure's aspect (taller than wide) centered in the canvas.
            let figureAspect = 0.45
            let height = size.height
            let width = min(size.width, height * figureAspect / 0.9)
            let offsetX = (size.width - width) / 2

            func rect(for region: BodyRegion) -> CGRect {
                CGRect(
                    x: offsetX + region.x * width,
                    y: region.y * height,
                    width: region.width * width,
                    height: region.height * height
                )
            }

            func path(for region: BodyRegion) -> Path {
                let frame = rect(for: region)
                switch region.shape {
                case .ellipse:
                    return Path(ellipseIn: frame)
                case .capsule:
                    return Path(roundedRect: frame, cornerRadius: frame.width / 2)
                case .roundedRect:
                    return Path(roundedRect: frame, cornerRadius: min(frame.width, frame.height) * 0.25)
                }
            }

            // Silhouette (context, non-tintable).
            for piece in BodyDiagram.silhouette {
                context.fill(path(for: piece), with: .color(Color(.systemGray5)))
            }

            // Muscle regions on top.
            for region in BodyDiagram.regions(for: side) {
                let color: Color
                if let score = scores[region.muscle], score > 0 {
                    color = BodyHeatmapView.heat(score)
                } else {
                    color = Color(.systemGray4)
                }
                context.fill(path(for: region), with: .color(color))
            }
        }
    }
}
