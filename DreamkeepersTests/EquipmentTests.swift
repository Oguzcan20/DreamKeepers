import XCTest
@testable import Dreamkeepers

final class EquipmentTests: XCTestCase {
    func testEquippedItemAddsStatBonus() {
        let catalog = DreamkeeperCatalog.starter
        var instance = DreamkeeperInstance(definitionID: "ember_fox")
        let baseStats = instance.currentStats(in: catalog)

        let weapon = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .rare, level: 5,
                                    statBonus: Stats(hp: 0, attack: 12, defense: 0, speed: 0))
        instance.equipped[EquipmentSlot.weapon.rawValue] = weapon.id

        let equippedStats = instance.currentStats(in: catalog, inventory: [weapon])

        XCTAssertEqual(equippedStats.attack, baseStats.attack + 12)
        XCTAssertEqual(equippedStats.hp, baseStats.hp)
    }

    func testUnknownEquippedItemIDIsIgnored() {
        let catalog = DreamkeeperCatalog.starter
        var instance = DreamkeeperInstance(definitionID: "ember_fox")
        instance.equipped[EquipmentSlot.weapon.rawValue] = UUID()

        let stats = instance.currentStats(in: catalog, inventory: [])
        let baseStats = instance.currentStats(in: catalog)

        XCTAssertEqual(stats, baseStats)
    }

    func testMultipleSlotsStack() {
        let catalog = DreamkeeperCatalog.starter
        var instance = DreamkeeperInstance(definitionID: "moon_hare")
        let baseStats = instance.currentStats(in: catalog)

        let charm = EquipmentItem(slot: .charm, name: "Test Charm", rarity: .epic, level: 3,
                                   statBonus: Stats(hp: 20, attack: 0, defense: 0, speed: 0))
        let ring = EquipmentItem(slot: .ring, name: "Test Ring", rarity: .common, level: 3,
                                  statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 5))
        instance.equipped[EquipmentSlot.charm.rawValue] = charm.id
        instance.equipped[EquipmentSlot.ring.rawValue] = ring.id

        let stats = instance.currentStats(in: catalog, inventory: [charm, ring])

        XCTAssertEqual(stats.hp, baseStats.hp + 20)
        XCTAssertEqual(stats.speed, baseStats.speed + 5)
    }
}
