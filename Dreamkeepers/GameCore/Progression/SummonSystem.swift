import Foundation

struct SummonResult: Equatable {
    var definition: DreamkeeperDefinition
    /// `false` for the very first copy of a species; every pull after that —
    /// including this one when `false` — lands in the roster as its own
    /// real instance, ready to feed into a manual fusion later.
    var isNew: Bool
}

/// Standard Summon: odds are fixed and shown to the player up front (spec:
/// no hidden mechanics). Pulls draw a rarity first, then a random catalog
/// entry of that rarity — this stays correct as the catalog grows, it just
/// needs every new rarity tier represented in `rarityOdds`.
enum SummonSystem {
    static let cost = 30

    /// Bulk pull: pay for `multiPullPaidCount` and get `multiPullBonusCount`
    /// extra for free — the classic "10+1" gacha bundle, priced as exactly
    /// 10 single pulls with no separate discount math to keep straight.
    static let multiPullPaidCount = 10
    static let multiPullBonusCount = 1
    static var multiPullTotalCount: Int { multiPullPaidCount + multiPullBonusCount }
    static var multiPullCost: Int { cost * multiPullPaidCount }

    /// Rarity -> probability. Must sum to 1.0 and cover every rarity actually
    /// present in the catalog, or those entries become unreachable.
    ///
    /// Legendary+Mythic combined started at 8% — player feedback was "too
    /// much legendary too often" — first cut to 4%/1%, then further to
    /// 1%/0.5% (still too frequent at 4%). The freed probability each time
    /// moved into common/uncommon so the floor stays generous even as the
    /// ceiling gets rarer. Equipment Summoning (`EquipmentSummonSystem`)
    /// shares this exact table rather than keeping its own dial, so the two
    /// gacha currencies always feel equally (un)lucky.
    /// `.exclusive` (Igo/Ames) sits at 0.01% per character, 0.02% combined —
    /// taken out of `.common` so the table still sums to 1.0. It never
    /// participates in pity (see `rollRarity(pullsSinceEpic:pullsSinceLegendary:)`
    /// below, which only ever raises a roll to `.epic`/`.legendary`) and
    /// `GameState.rollAndAddSummon` re-rolls it to `.mythic` once both
    /// exclusive characters are owned.
    static let rarityOdds: [(Rarity, Double)] = [
        (.common, 0.2498),
        (.uncommon, 0.335),
        (.rare, 0.27),
        (.epic, 0.13),
        (.legendary, 0.01),
        (.mythic, 0.005),
        (.exclusive, 0.0002)
    ]

    /// Draws a rarity from `rarityOdds` alone — the shared building block
    /// behind `rollDefinition` below and `EquipmentSummonSystem.rollItem`,
    /// so both summon types roll off the exact same cumulative-threshold
    /// logic instead of two copies that could quietly drift apart.
    static func rollRarity(roll: Double = .random(in: 0..<1)) -> Rarity {
        var cumulative = 0.0
        for (rarity, weight) in rarityOdds {
            cumulative += weight
            if roll < cumulative {
                return rarity
            }
        }
        return rarityOdds.last!.0
    }

    /// Pity floors so a long stretch of bad luck always has a ceiling:
    /// an Epic+ is guaranteed within `epicPityThreshold` pulls of the last
    /// one, and a Legendary+ within `legendaryPityThreshold`. Both counters
    /// live in `GameSave` (shared by Dreamkeeper and Equipment Summoning —
    /// see `pullsSinceEpicSummon`/`pullsSinceLegendarySummon`) and are the
    /// caller's job to update from the returned rarity; this function only
    /// reads them to decide whether to raise the floor on this one roll.
    static let epicPityThreshold = 10
    static let legendaryPityThreshold = 75

    /// Rolls a rarity the normal way, then raises it to the pity floor (if
    /// any) that this pull would otherwise miss. A roll that's already at or
    /// above a floor is left alone — pity only ever helps, never hurts.
    static func rollRarity(pullsSinceEpic: Int, pullsSinceLegendary: Int, roll: Double = .random(in: 0..<1)) -> Rarity {
        var rarity = rollRarity(roll: roll)
        if pullsSinceLegendary + 1 >= legendaryPityThreshold, rarity < .legendary {
            rarity = .legendary
        } else if pullsSinceEpic + 1 >= epicPityThreshold, rarity < .epic {
            rarity = .epic
        }
        return rarity
    }

    /// `isSummonable` is filtered out here — Ultimate Olf is the only
    /// definition with it set to `false` today, and this is the single
    /// funnel every roll (pity-raised or not) passes through, so excluding
    /// him here keeps him out of the gacha pool at whatever rarity he's
    /// tagged with, without touching the odds table itself.
    static func rollDefinition(from catalog: DreamkeeperCatalog, rarity: Rarity) -> DreamkeeperDefinition {
        let candidates = catalog.definitions.filter { $0.rarity == rarity && $0.isSummonable }
        if !candidates.isEmpty { return candidates.randomElement()! }
        let summonable = catalog.definitions.filter(\.isSummonable)
        return summonable.randomElement() ?? catalog.definitions.randomElement()!
    }

    static func rollDefinition(from catalog: DreamkeeperCatalog, roll: Double = .random(in: 0..<1)) -> DreamkeeperDefinition {
        rollDefinition(from: catalog, rarity: rollRarity(roll: roll))
    }
}
