import Foundation
import Testing
@testable import FitnessCore

@Suite("BodyDiagram")
struct BodyDiagramTests {
    @Test func everyMuscleGroupHasARegion() {
        let covered = Set(BodyDiagram.frontRegions.map(\.muscle))
            .union(BodyDiagram.backRegions.map(\.muscle))
        #expect(covered == Set(MuscleGroup.allCases))
    }

    @Test func regionsAreOnTheCorrectSide() {
        #expect(BodyDiagram.frontRegions.allSatisfy { $0.muscle.side == .front })
        #expect(BodyDiagram.backRegions.allSatisfy { $0.muscle.side == .back })
    }

    @Test func allFramesWithinNormalizedBounds() {
        for region in BodyDiagram.frontRegions + BodyDiagram.backRegions + BodyDiagram.silhouette {
            #expect(region.x >= 0 && region.y >= 0, "\(region.muscle) origin")
            #expect(region.x + region.width <= 1.0, "\(region.muscle) right edge")
            #expect(region.y + region.height <= 1.0, "\(region.muscle) bottom edge")
        }
    }

    @Test func bilateralPairsAreSymmetric() {
        // For every muscle with 2 regions, the pair mirrors around x = 0.5.
        for regions in [BodyDiagram.frontRegions, BodyDiagram.backRegions] {
            let byMuscle = Dictionary(grouping: regions, by: \.muscle)
            for (muscle, group) in byMuscle where group.count == 2 {
                let leftCenter = group[0].x + group[0].width / 2
                let rightCenter = group[1].x + group[1].width / 2
                #expect(abs((leftCenter + rightCenter) / 2 - 0.5) < 0.0001, "\(muscle)")
                #expect(abs(group[0].y - group[1].y) < 0.0001, "\(muscle)")
            }
        }
    }
}
