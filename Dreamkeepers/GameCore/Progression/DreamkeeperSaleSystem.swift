import Foundation

/// Selling a roster Dreamkeeper back for currency — a soft-currency sink for
/// duplicates/fodder that didn't get used for fusion. Gold scales with
/// rarity, level and stars; Dream Gems only come back at Legendary/Mythic,
/// matching how those two rarities are the only ones treated as
/// gem-tier drops elsewhere (`SummonSystem`, `EquipmentFactory`).
enum DreamkeeperSaleSystem {
    static func goldValue(for rarity: Rarity, level: Int, stars: Int) -> Int {
        let base: Int
        switch rarity {
        case .common: base = 15
        case .uncommon: base = 30
        case .rare: base = 60
        case .epic: base = 120
        case .legendary: base = 250
        case .mythic: base = 400
        case .exclusive: base = 1000 // Never actually reachable — GameState.canSellDreamkeeper blocks selling Igo/Ames.
        }
        return base + (level - 1) * 3 + stars * 20
    }

    static func gemValue(for rarity: Rarity) -> Int {
        switch rarity {
        case .legendary: return 5
        case .mythic: return 12
        case .exclusive: return 25 // Never actually reachable — see goldValue.
        default: return 0
        }
    }
}
