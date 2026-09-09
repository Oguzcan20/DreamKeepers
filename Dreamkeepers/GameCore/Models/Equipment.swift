import SwiftUI

enum EquipmentSlot: String, Codable, CaseIterable, Identifiable {
    case weapon, charm, cloak, ring

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .weapon: return "wand.and.rays"
        case .charm: return "seal.fill"
        case .cloak: return "theatermask.and.paintbrush.fill"
        case .ring: return "circle.circle.fill"
        }
    }

    /// Stat each slot primarily boosts, per spec (weapons hit, charms protect
    /// life, cloaks defend, rings quicken).
    var primaryStat: WritableKeyPath<Stats, Double> {
        switch self {
        case .weapon: return \.attack
        case .charm: return \.hp
        case .cloak: return \.defense
        case .ring: return \.speed
        }
    }
}

struct EquipmentItem: Codable, Identifiable, Equatable {
    var id: UUID
    var slot: EquipmentSlot
    var name: String
    var rarity: Rarity
    var level: Int
    var statBonus: Stats
    /// 0 (no fusion yet) through `StarFusionSystem.maxStars` — same manual
    /// duplicate-fusion mechanic as Dreamkeepers (see `GameState.duplicates(ofItem:)`).
    var stars: Int
    /// Duplicates already banked toward the *next* star tier, same banked-
    /// progress model as `DreamkeeperInstance.fusionProgress`.
    var fusionProgress: Int

    init(id: UUID = UUID(), slot: EquipmentSlot, name: String, rarity: Rarity, level: Int, statBonus: Stats, stars: Int = 0, fusionProgress: Int = 0) {
        self.id = id
        self.slot = slot
        self.name = name
        self.rarity = rarity
        self.level = level
        self.statBonus = statBonus
        self.stars = stars
        self.fusionProgress = fusionProgress
    }

    /// Custom decode so saves written before `stars` or `fusionProgress`
    /// existed still load instead of crashing on a missing key.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        slot = try container.decode(EquipmentSlot.self, forKey: .slot)
        name = try container.decode(String.self, forKey: .name)
        rarity = try container.decode(Rarity.self, forKey: .rarity)
        level = try container.decode(Int.self, forKey: .level)
        statBonus = try container.decode(Stats.self, forKey: .statBonus)
        stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        fusionProgress = try container.decodeIfPresent(Int.self, forKey: .fusionProgress) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slot, forKey: .slot)
        try container.encode(name, forKey: .name)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(level, forKey: .level)
        try container.encode(statBonus, forKey: .statBonus)
        try container.encode(stars, forKey: .stars)
        try container.encode(fusionProgress, forKey: .fusionProgress)
    }

    private enum CodingKeys: String, CodingKey {
        case id, slot, name, rarity, level, statBonus, stars, fusionProgress
    }

    /// "Same kind" for fusion purposes: identical slot, name, and rarity —
    /// the exact stat magnitude can differ slightly by drop stage, same as
    /// two Dreamkeeper pulls of the same species differing only by nothing.
    func isSameKind(as other: EquipmentItem) -> Bool {
        slot == other.slot && name == other.name && rarity == other.rarity
    }

    /// Stat bonus including the star-fusion bonus, same 6%-per-star formula
    /// used for Dreamkeepers.
    var effectiveStatBonus: Stats {
        statBonus * (1 + StarFusionSystem.statBonusPerStar * Double(stars))
    }
}
