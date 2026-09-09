import SwiftUI

enum Rarity: String, Codable, CaseIterable, Comparable, Identifiable {
    case common, uncommon, rare, epic, legendary, mythic
    /// The top tier, permanently capped at exactly two catalog entries (Igo
    /// and Ames) — see `TwinBond` and `DreamkeeperCatalog`. Not a normal
    /// power step above Mythic so much as a distinct, one-of-a-kind class.
    case exclusive

    var id: String { rawValue }

    private var sortOrder: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        case .mythic: return 5
        case .exclusive: return 6
        }
    }

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var displayName: String { rawValue.capitalized }

    /// The two-stop palette this rarity draws from — brighter and richer as
    /// rarity climbs. `gradient` and `primaryColor` both derive from this so
    /// every rarity-tinted effect in the app (cards, summon reveal bursts)
    /// stays visually consistent with one source of truth.
    private var gradientColors: [Color] {
        switch self {
        case .common: return [Color(white: 0.55), Color(white: 0.4)]
        case .uncommon: return [Color(red: 0.4, green: 0.75, blue: 0.5), Color(red: 0.25, green: 0.55, blue: 0.35)]
        case .rare: return [Color(red: 0.35, green: 0.6, blue: 0.95), Color(red: 0.2, green: 0.4, blue: 0.8)]
        case .epic: return [Color(red: 0.7, green: 0.4, blue: 0.95), Color(red: 0.5, green: 0.2, blue: 0.8)]
        case .legendary: return [Color(red: 0.98, green: 0.75, blue: 0.25), Color(red: 0.9, green: 0.5, blue: 0.15)]
        case .mythic: return [Color(red: 1.0, green: 0.4, blue: 0.7), Color(red: 0.6, green: 0.3, blue: 0.95)]
        case .exclusive: return [Color(red: 1.0, green: 0.86, blue: 0.4), Color(red: 0.08, green: 0.08, blue: 0.1)]
        }
    }

    /// Base gradient used for card frames — richer as rarity climbs.
    var gradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// A single representative color for this rarity — used where a flat
    /// tint reads better than a gradient (glows, particle bursts).
    var primaryColor: Color { gradientColors[0] }

    var glows: Bool { self >= .epic }

    /// How many burst particles a summon reveal should spawn for this
    /// rarity — a bigger, busier flourish the rarer the pull.
    var summonBurstParticleCount: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 4
        case .rare: return 6
        case .epic: return 9
        case .legendary: return 13
        case .mythic: return 18
        case .exclusive: return 24
        }
    }
}
