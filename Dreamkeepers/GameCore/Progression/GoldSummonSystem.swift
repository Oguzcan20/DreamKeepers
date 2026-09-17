import Foundation

/// A cheap, Gold-funded alternative to the premium (Dream Gems)
/// Summoning Shrine pull — spends the currency players already earn just
/// from playing, but with odds tuned much stingier than
/// `SummonSystem.rarityOdds` so it never competes with the premium
/// banner. `.exclusive` (Igo/Ames) never appears in this table — they
/// stay reachable only through the premium gacha or the Shop purchase.
/// Deliberately has no pity mechanic of its own (see
/// `GameState.rollAndAddGoldSummon`) — pity is the premium banner's
/// value proposition, not this one's.
enum GoldSummonSystem {
    static let cost = 150
    static let multiPullPaidCount = 10
    static let multiPullBonusCount = 1
    static let multiPullTotalCount = 11
    static let multiPullCost = 1500

    /// Sums to 1.0. Roughly a quarter of `SummonSystem`'s rare-and-above
    /// odds, and Legendary/Mythic are pushed an order of magnitude further
    /// out than the premium table's — "maximal selten" by design.
    static let rarityOdds: [(Rarity, Double)] = [
        (.common, 0.55),
        (.uncommon, 0.30),
        (.rare, 0.12),
        (.epic, 0.025),
        (.legendary, 0.0045),
        (.mythic, 0.0005)
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
