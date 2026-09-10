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

    // MARK: - Auto-equip / auto-unequip

    private func makeState(inventory: [EquipmentItem], equipped: [EquipmentSlot: UUID] = [:]) -> GameState {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.inventory = inventory
        for (slot, id) in equipped {
            seed.roster[0].equipped[slot.rawValue] = id
        }
        try? saveSystem.save(seed)
        return GameState(platform: MockPlatformService(), saveSystem: saveSystem)
    }

    func testAutoEquipFillsEmptySlotsFromInventory() {
        let weapon = EquipmentItem(slot: .weapon, name: "Blade", rarity: .rare, level: 1,
                                    statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0))
        let state = makeState(inventory: [weapon])

        XCTAssertTrue(state.canAutoEquip(state.roster[0]))
        XCTAssertTrue(state.autoEquipBest(for: state.roster[0]))
        XCTAssertEqual(state.equippedItem(.weapon, for: state.roster[0])?.id, weapon.id)
    }

    func testUnequipAllClearsEverySlotButKeepsItems() {
        let weapon = EquipmentItem(slot: .weapon, name: "Blade", rarity: .rare, level: 1, statBonus: .zero)
        let charm = EquipmentItem(slot: .charm, name: "Charm", rarity: .epic, level: 1, statBonus: .zero)
        let state = makeState(inventory: [weapon, charm],
                              equipped: [.weapon: weapon.id, .charm: charm.id])

        XCTAssertTrue(state.canUnequipAll(state.roster[0]))
        XCTAssertTrue(state.unequipAll(for: state.roster[0]))

        XCTAssertNil(state.equippedItem(.weapon, for: state.roster[0]))
        XCTAssertNil(state.equippedItem(.charm, for: state.roster[0]))
        XCTAssertEqual(state.inventory.count, 2, "Unequip returns gear to storage, never destroys it")
        XCTAssertFalse(state.canUnequipAll(state.roster[0]))
    }

    func testUnequipAllIsNoOpWhenNothingEquipped() {
        let state = makeState(inventory: [])
        XCTAssertFalse(state.canUnequipAll(state.roster[0]))
        XCTAssertFalse(state.unequipAll(for: state.roster[0]))
    }
}
