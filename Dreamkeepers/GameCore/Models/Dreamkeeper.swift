import SwiftUI

/// Static, data-driven description of a Dreamkeeper species. New characters are
/// added by appending to the catalog — combat and progression code never
/// switches on identity.
struct DreamkeeperDefinition: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var element: Element
    var role: Role
    var rarity: Rarity
    var baseStats: Stats
    /// Stat gained per level beyond 1.
    var growthPerLevel: Stats
    var ultimate: UltimateSkill
    var activeSkill: ActiveSkill
    var passive: PassiveTrait
    var symbol: String
    var flavorText: String
    /// Groups definitions that are "the same character" for fusion purposes
    /// even though they have distinct `id`s — currently only Olf's six
    /// entries (`family: "olf"`), so any element variant pulled later from
    /// Summoning can be fused into whichever one the player is actually
    /// raising. `nil` (the default) means fusion stays strict-`id` for
    /// every other Dreamkeeper, unchanged from before this field existed.
    /// See `GameState.duplicates(of:)`.
    var family: String? = nil
    /// Whether this definition can ever be the result of a Summon roll.
    /// `false` only for Ultimate Olf, who is granted solely through the
    /// post-onboarding secret gesture and must never turn up in the gacha
    /// pool at any rarity. Defaults to `true` for every other Dreamkeeper.
    /// See `SummonSystem.rollDefinition(from:rarity:)`.
    var isSummonable: Bool = true
}

/// A specific Dreamkeeper owned by the player: a definition plus progression.
struct DreamkeeperInstance: Codable, Identifiable, Equatable {
    var id: UUID
    var definitionID: String
    var level: Int
    var exp: Int
    /// 0 (no fusion yet) through `StarFusionSystem.maxStars`.
    var stars: Int
    /// Duplicates already banked toward the *next* star tier — a fusion no
    /// longer has to hand over the tier's full cost in one go; every fuse
    /// adds to this and the star only advances once it's enough (see
    /// `StarFusionSystem.applyFusion`).
    var fusionProgress: Int
    /// EquipmentSlot.rawValue -> equipped EquipmentItem.id. At most one item per slot.
    var equipped: [String: UUID]

    init(id: UUID = UUID(), definitionID: String, level: Int = 1, exp: Int = 0, stars: Int = 0,
         fusionProgress: Int = 0, equipped: [String: UUID] = [:]) {
        self.id = id
        self.definitionID = definitionID
        self.level = level
        self.exp = exp
        self.stars = stars
        self.fusionProgress = fusionProgress
        self.equipped = equipped
    }

    /// Custom decode so saves written before `stars` moved from a 1-indexed
    /// to a 0-indexed scale, before manual fusion replaced the old
    /// duplicate-shard counter, or before banked `fusionProgress` existed,
    /// still load instead of crashing on a missing or now-unused key.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        definitionID = try container.decode(String.self, forKey: .definitionID)
        level = try container.decode(Int.self, forKey: .level)
        exp = try container.decode(Int.self, forKey: .exp)
        stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        fusionProgress = try container.decodeIfPresent(Int.self, forKey: .fusionProgress) ?? 0
        equipped = try container.decodeIfPresent([String: UUID].self, forKey: .equipped) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(definitionID, forKey: .definitionID)
        try container.encode(level, forKey: .level)
        try container.encode(exp, forKey: .exp)
        try container.encode(stars, forKey: .stars)
        try container.encode(fusionProgress, forKey: .fusionProgress)
        try container.encode(equipped, forKey: .equipped)
    }

    private enum CodingKeys: String, CodingKey {
        case id, definitionID, level, exp, stars, fusionProgress, equipped
        case duplicateShards // legacy key, migration-only (ignored on decode)
    }
}

extension DreamkeeperInstance {
    func definition(in catalog: DreamkeeperCatalog) -> DreamkeeperDefinition? {
        catalog.definition(for: definitionID)
    }

    /// Stats at the current level, including passive bonus, star bonus, and
    /// whatever is equipped (looked up from the player's shared inventory).
    func currentStats(in catalog: DreamkeeperCatalog, inventory: [EquipmentItem] = []) -> Stats {
        guard let def = definition(in: catalog) else { return .zero }
        let levelGrowth = def.growthPerLevel * Double(level - 1)
        let starBonus = def.baseStats * (StarFusionSystem.statBonusPerStar * Double(stars))
        let equipmentBonus = equipped.values
            .compactMap { itemID in inventory.first { $0.id == itemID } }
            .reduce(Stats.zero) { $0 + $1.effectiveStatBonus }
        return (def.baseStats + levelGrowth + starBonus + def.passive.statBonus + equipmentBonus).rounded
    }
}
