import Foundation

/// Gold-cost equipment upgrades, applied from the Inventory item detail sheet. Each level
/// compounds the item's stat bonus by a flat percentage; cost scales with
/// rarity and current level so late-game upgrades stay a meaningful sink.
enum EquipmentUpgrade {
    static let maxLevel = 10
    static let growthPerLevel = 0.12

    static func canUpgrade(_ item: EquipmentItem) -> Bool {
        item.level < maxLevel
    }

    static func cost(for item: EquipmentItem) -> Int {
        let rarityMultiplier: Double
        switch item.rarity {
        case .common: rarityMultiplier = 1.0
        case .uncommon: rarityMultiplier = 1.3
        case .rare: rarityMultiplier = 1.7
        case .epic: rarityMultiplier = 2.2
        case .legendary: rarityMultiplier = 2.8
        case .mythic: rarityMultiplier = 3.6
        case .exclusive: rarityMultiplier = 3.6 // Equipment never actually rolls .exclusive; kept for switch exhaustiveness.
        }
        let base = 25 + item.level * 20
        return Int((Double(base) * rarityMultiplier).rounded())
    }

    /// Returns the item at its next level with a compounded stat bonus.
    /// No-op (returns the same item) once `maxLevel` is reached.
    static func upgraded(_ item: EquipmentItem) -> EquipmentItem {
        guard canUpgrade(item) else { return item }
        var item = item
        item.level += 1
        item.statBonus = (item.statBonus * (1 + growthPerLevel)).rounded
        return item
    }
}
