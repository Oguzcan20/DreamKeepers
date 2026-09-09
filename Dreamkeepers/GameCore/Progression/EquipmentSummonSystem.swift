import Foundation

/// Equipment Summon: same 30-gem single / 300-gem "10+1" pricing as
/// `SummonSystem`, and the exact same rarity odds (`SummonSystem.rollRarity`)
/// so the two gacha currencies feel equally (un)lucky — only the payout
/// differs: an `EquipmentItem` sized for the player's current stage instead
/// of a `DreamkeeperDefinition`.
enum EquipmentSummonSystem {
    static let cost = 30

    static let multiPullPaidCount = 10
    static let multiPullBonusCount = 1
    static var multiPullTotalCount: Int { multiPullPaidCount + multiPullBonusCount }
    static var multiPullCost: Int { cost * multiPullPaidCount }

    /// `.exclusive` is Igo/Ames only — a character rarity with no equipment
    /// equivalent — so a rarity landing there is treated as `.mythic` here,
    /// same top-tier payout as everywhere else in the equipment loot table.
    /// Applied in this single rarity-taking overload (rather than only in
    /// the roll-based one below) so `GameState.rollAndAddEquipmentSummon`'s
    /// pity-aware path — which resolves its own rarity and calls straight
    /// into this overload — can't slip an `.exclusive`-rarity item into the
    /// inventory.
    static func rollItem(forStage stage: Int, rarity: Rarity) -> EquipmentItem {
        let rarity = rarity == .exclusive ? .mythic : rarity
        return EquipmentFactory.item(forStage: stage, rarity: rarity)
    }

    static func rollItem(forStage stage: Int, roll: Double = .random(in: 0..<1)) -> EquipmentItem {
        rollItem(forStage: stage, rarity: SummonSystem.rollRarity(roll: roll))
    }
}
