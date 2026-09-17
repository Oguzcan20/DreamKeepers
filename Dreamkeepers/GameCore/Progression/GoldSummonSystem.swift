import Foundation

/// A cheap, Gold-funded alternative to the premium (Dream Gems)
/// Summoning Shrine pull — spends the currency players already earn just
/// from playing, but hard-capped at Epic: Legendary, Mythic, and
/// `.exclusive` (Igo/Ames) never appear in this table at all, so the top
/// end of the roster stays reachable only through the premium gacha or the
/// Shop purchase. Deliberately has no pity mechanic of its own (see
/// `GameState.rollAndAddGoldSummon`) — pity is the premium banner's
/// value proposition, not this one's.
enum GoldSummonSystem {
    static let cost = 150
    static let multiPullPaidCount = 10
    static let multiPullBonusCount = 1
    static let multiPullTotalCount = 11
    static let multiPullCost = 1500

    /// Sums to 1.0. Epic is the ceiling — nothing above it appears here, so
    /// there's no weight to give Legendary/Mythic/Exclusive in the first
    /// place, unlike `SummonSystem.rarityOdds` which reaches all the way up.
    static let rarityOdds: [(Rarity, Double)] = [
        (.common, 0.55),
        (.uncommon, 0.30),
        (.rare, 0.12),
        (.epic, 0.03)
    ]

    static func rollRarity(roll: Double = .random(in: 0..<1)) -> Rarity {
        var cumulative = 0.0
        for (rarity, weight) in rarityOdds {
            cumulative += weight
            if roll < cumulative { return rarity }
        }
        return rarityOdds.last?.0 ?? .common
    }

    static func rollDefinition(from catalog: DreamkeeperCatalog, roll: Double = .random(in: 0..<1)) -> DreamkeeperDefinition {
        SummonSystem.rollDefinition(from: catalog, rarity: rollRarity(roll: roll))
    }
}
