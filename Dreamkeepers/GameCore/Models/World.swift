import SwiftUI

/// A campaign chapter: a fixed run of stages ending in a boss. Global stage
/// numbers stay contiguous across worlds (world 2 starts where world 1 ends)
/// so existing boss-detection (`stage % stagesPerWorld == 0`) keeps working.
struct World: Identifiable, Equatable {
    static let stagesPerWorld = 5

    var id: Int
    var name: String
    var description: String
    var accentColor: Color
    var elementBias: [Element]
    var bossName: String
    /// Extra stat multiplier stacked on top of the linear per-stage curve —
    /// creates a felt jump between difficulty tiers (spec section 7:
    /// Einsteiger/Fortgeschritten/Schwer/Sehr schwer/Endgame/Final) instead
    /// of pure smooth growth.
    var difficultyMultiplier: Double = 1.0

    var firstStage: Int { (id - 1) * World.stagesPerWorld + 1 }
    var lastStage: Int { id * World.stagesPerWorld }
    var stages: ClosedRange<Int> { firstStage...lastStage }
}
