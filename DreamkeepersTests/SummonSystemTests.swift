import XCTest
@testable import Dreamkeepers

final class SummonSystemTests: XCTestCase {
    func testRarityOddsSumToOne() {
        let total = SummonSystem.rarityOdds.reduce(0.0) { $0 + $1.1 }
        XCTAssertEqual(total, 1.0, accuracy: 0.0001)
    }

    func testLowRollPicksFirstRarityBucket() {
        let def = SummonSystem.rollDefinition(from: .starter, roll: 0.0)
        XCTAssertEqual(def.rarity, SummonSystem.rarityOdds[0].0)
    }

    func testHighRollPicksLastRarityBucket() {
        let def = SummonSystem.rollDefinition(from: .starter, roll: 0.9999)
        XCTAssertEqual(def.rarity, SummonSystem.rarityOdds.last!.0)
    }

    func testPerformSummonDeductsGemsAndBlocksWhenPoor() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        let startingGems = state.save.dreamGems
        XCTAssertTrue(state.canAffordSummon)

        let result = state.performSummon()
        XCTAssertNotNil(result)
        XCTAssertEqual(state.save.dreamGems, startingGems - SummonSystem.cost)

        // Drain remaining gems to below cost, then confirm the guard holds.
        while state.canAffordSummon {
            state.performSummon()
        }
        XCTAssertNil(state.performSummon())
    }

    func testDuplicateSummonBecomesItsOwnRosterEntry() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.dreamGems = 5_000 // enough for many pulls regardless of SummonSystem.cost
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        // With a 5-entry catalog and the whole catalog reachable from the start,
        // 40 pulls make hitting the already-owned starter overwhelmingly likely.
        var sawDuplicate = false
        var pullCount = 0
        for _ in 0..<40 {
            guard state.canAffordSummon, let result = state.performSummon() else { break }
            pullCount += 1
            if !result.isNew { sawDuplicate = true }
            // Every pull — new or duplicate — grows the roster by exactly
            // one, on top of the 1 starter Dreamkeeper the save begins with.
            XCTAssertEqual(state.roster.count, pullCount + 1)
        }
        XCTAssertTrue(sawDuplicate, "Expected at least one duplicate pull across many summons")
    }

    func testExclusiveRollGrantsMaxLevelMaxStarInstance() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        // 0.9999 lands in the Exclusive band per `SummonSystem.rarityOdds`
        // (same roll `testHighRollPicksLastRarityBucket` uses to reach it).
        let result = state.rollAndAddSummon(roll: 0.9999)
        XCTAssertEqual(result.definition.rarity, .exclusive)

        let granted = state.roster.first { $0.definitionID == result.definition.id }
        XCTAssertNotNil(granted)
        XCTAssertEqual(granted?.level, LevelSystem.maxLevel)
        XCTAssertEqual(granted?.stars, StarFusionSystem.maxStars)
    }

    func testExclusiveRollFallsBackToMythicOnceBothOwned() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.roster.append(DreamkeeperInstance(definitionID: "igo", level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars))
        seed.roster.append(DreamkeeperInstance(definitionID: "ames", level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars))
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        // A roll that lands squarely in the (now unreachable) Exclusive band
        // must never crash and must never grant a 3rd copy — it silently
        // downgrades to .mythic instead of wasting the player's pull.
        let result = state.rollAndAddSummon(roll: 0.9999)
        XCTAssertEqual(result.definition.rarity, .mythic)
    }
}
