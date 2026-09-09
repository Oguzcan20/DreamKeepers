import Foundation

/// Procedural equipment drops for the MVP loot loop. Hand-authored sets can
/// replace or extend this later without touching GameState/UI — both just
/// deal in `EquipmentItem`.
enum EquipmentFactory {
    private static let namesBySlot: [EquipmentSlot: [String]] = [
        .weapon: ["Ember Dagger", "Bramble Wand", "Tidecaller Blade", "Lunar Piercer", "Astral Spear", "Crystal Cleaver"],
        .charm: ["Moonstone Charm", "Warding Sigil", "Dream Locket", "Ember Talisman", "Tideheart Pendant", "Bloomseed Charm"],
        .cloak: ["Woven Nightcloak", "Starlit Mantle", "Bark Shroud", "Emberweave Cloak", "Tidewoven Cape", "Crystalline Veil"],
        .ring: ["Whisper Ring", "Bloomband", "Rift Loop", "Emberband", "Tideloop Ring", "Duskbrand Ring"]
    ]

    /// Chance a victory drops an item at all; boss stages always drop.
    static func shouldDrop(isBoss: Bool) -> Bool {
        isBoss || Double.random(in: 0...1) < 0.35
    }

    static func randomItem(forStage stage: Int, isBoss: Bool) -> EquipmentItem {
        item(forStage: stage, rarity: rollRarity(isBoss: isBoss))
    }

    /// Builds an item of an already-decided rarity and (optionally) slot —
    /// the shared stat-magnitude math behind `randomItem` above (which rolls
    /// its own loot-table rarity for battle drops) and Equipment Summoning
    /// (`EquipmentSummonSystem`, which rolls rarity from the gacha odds in
    /// `SummonSystem` instead). Keeping the magnitude formula in one place
    /// means a battle-dropped and a summoned item of the same slot/rarity/
    /// stage are worth exactly the same.
    static func item(forStage stage: Int, rarity: Rarity, slot: EquipmentSlot? = nil) -> EquipmentItem {
        let slot = slot ?? EquipmentSlot.allCases.randomElement()!
        let name = namesBySlot[slot]?.randomElement() ?? "Dream Relic"

        let rarityMultiplier: Double
        switch rarity {
        case .common: rarityMultiplier = 1.0
        case .uncommon: rarityMultiplier = 1.4
        case .rare: rarityMultiplier = 1.9
        case .epic: rarityMultiplier = 2.6
        case .legendary: rarityMultiplier = 3.5
        case .mythic: rarityMultiplier = 4.6
        case .exclusive: rarityMultiplier = 4.6 // Equipment never actually rolls .exclusive; kept for switch exhaustiveness — see EquipmentSummonSystem.rollItem.
        }

        let magnitude = (4 + Double(stage) * 1.1) * rarityMultiplier
        var bonus = Stats.zero
        bonus[keyPath: slot.primaryStat] = magnitude.rounded()

        return EquipmentItem(slot: slot, name: name, rarity: rarity, level: 1, statBonus: bonus)
    }

    private static func rollRarity(isBoss: Bool) -> Rarity {
        let roll = Double.random(in: 0...1)
        let table: [(Double, Rarity)] = isBoss
            ? [(0.30, .rare), (0.60, .epic), (0.85, .legendary), (1.0, .mythic)]
            : [(0.55, .common), (0.82, .uncommon), (0.96, .rare), (1.0, .epic)]

        for (threshold, rarity) in table where roll <= threshold {
            return rarity
        }
        return table.last!.1
    }
}
