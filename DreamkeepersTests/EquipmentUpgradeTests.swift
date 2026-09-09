import XCTest
@testable import Dreamkeepers

final class EquipmentUpgradeTests: XCTestCase {
    func testUpgradeIncrementsLevelAndGrowsStatBonus() {
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .rare, level: 1,
                                  statBonus: Stats(hp: 0, attack: 100, defense: 0, speed: 0))
        let upgraded = EquipmentUpgrade.upgraded(item)

        XCTAssertEqual(upgraded.level, 2)
        XCTAssertEqual(upgraded.id, item.id, "Upgrading must preserve identity so equipped references stay valid")
        XCTAssertGreaterThan(upgraded.statBonus.attack, item.statBonus.attack)
    }

    func testUpgradeIsNoOpAtMaxLevel() {
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .rare, level: EquipmentUpgrade.maxLevel,
                                  statBonus: Stats(hp: 0, attack: 100, defense: 0, speed: 0))
        XCTAssertFalse(EquipmentUpgrade.canUpgrade(item))
        let result = EquipmentUpgrade.upgraded(item)
        XCTAssertEqual(result, item)
    }

    func testCostScalesWithRarityAndLevel() {
        let common = EquipmentItem(slot: .ring, name: "A", rarity: .common, level: 1, statBonus: .zero)
        let mythic = EquipmentItem(slot: .ring, name: "B", rarity: .mythic, level: 1, statBonus: .zero)
        XCTAssertGreaterThan(EquipmentUpgrade.cost(for: mythic), EquipmentUpgrade.cost(for: common))

        let lowLevel = EquipmentItem(slot: .ring, name: "C", rarity: .common, level: 1, statBonus: .zero)
        let highLevel = EquipmentItem(slot: .ring, name: "D", rarity: .common, level: 5, statBonus: .zero)
        XCTAssertGreaterThan(EquipmentUpgrade.cost(for: highLevel), EquipmentUpgrade.cost(for: lowLevel))
    }

    func testGameStateUpgradeDeductsGoldAndPersistsSameID() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .common, level: 1,
                                  statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0))
        seed.inventory = [item]
        seed.gold = 1_000
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let cost = EquipmentUpgrade.cost(for: item)
        let startingGold = state.save.gold

        XCTAssertTrue(state.upgradeEquipment(item))
        XCTAssertEqual(state.save.gold, startingGold - cost)
        XCTAssertEqual(state.inventory.count, 1)
        XCTAssertEqual(state.inventory[0].id, item.id)
        XCTAssertEqual(state.inventory[0].level, 2)
    }

    func testGameStateUpgradeFailsWhenTooPoor() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .mythic, level: 1,
                                  statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0))
        seed.inventory = [item]
        seed.gold = 0
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertFalse(state.upgradeEquipment(item))
        XCTAssertEqual(state.inventory[0].level, 1)
    }

    func testUpgradingEquippedItemRaisesWearerStats() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .common, level: 1,
                                  statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0))
        seed.inventory = [item]
        seed.gold = 1_000
        seed.roster[0].equipped[EquipmentSlot.weapon.rawValue] = item.id
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let statsBefore = state.currentStats(for: state.roster[0])
        XCTAssertTrue(state.upgradeEquipment(item))
        let statsAfter = state.currentStats(for: state.roster[0])

        XCTAssertGreaterThan(statsAfter.attack, statsBefore.attack)
        XCTAssertEqual(state.wearer(of: state.inventory[0])?.id, state.roster[0].id)
    }
}
