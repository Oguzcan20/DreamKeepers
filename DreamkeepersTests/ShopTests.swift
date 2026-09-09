import XCTest
@testable import Dreamkeepers

final class ShopTests: XCTestCase {
    func testGemPackGrantsGemsWithoutCost() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let item = ShopCatalog.gemPacks[0]
        let startingGems = state.save.dreamGems
        let startingGold = state.save.gold

        XCTAssertTrue(state.purchase(item))
        XCTAssertEqual(state.save.dreamGems, startingGems + item.gemsGranted)
        XCTAssertEqual(state.save.gold, startingGold, "Gem packs shouldn't touch gold")
    }

    func testGoldExchangeDeductsGemsAndGrantsGold() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.dreamGems = 1_000
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let item = ShopCatalog.goldExchanges[0]
        let startingGems = state.save.dreamGems
        let startingGold = state.save.gold

        XCTAssertTrue(state.purchase(item))
        XCTAssertEqual(state.save.dreamGems, startingGems - item.gemCost)
        XCTAssertEqual(state.save.gold, startingGold + item.goldGranted)
    }

    func testGoldExchangeFailsWhenTooPoorInGems() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.dreamGems = 0
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let item = ShopCatalog.goldExchanges[0]
        XCTAssertFalse(state.canPurchase(item))
        XCTAssertFalse(state.purchase(item))
        XCTAssertEqual(state.save.gold, 100, "Failed purchase must not grant anything")
    }

    func testStarterPackClaimableOnlyOnce() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let item = ShopCatalog.starterPack
        XCTAssertFalse(state.isPurchased(item))
        XCTAssertTrue(state.purchase(item))
        XCTAssertTrue(state.isPurchased(item))

        let goldAfterFirst = state.save.gold
        XCTAssertFalse(state.purchase(item), "Starter pack can't be bought twice")
        XCTAssertEqual(state.save.gold, goldAfterFirst, "Second attempt must not grant again")
    }

    func testExclusiveCharacterPurchaseGrantsMaxLevelMaxStarInstanceOnce() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let item = ShopCatalog.exclusiveCharacters.first { $0.grantsDefinitionID == "igo" }!
        let startingRosterCount = state.roster.count

        XCTAssertFalse(state.isPurchased(item))
        XCTAssertTrue(state.purchase(item))
        XCTAssertTrue(state.isPurchased(item))
        XCTAssertEqual(state.roster.count, startingRosterCount + 1)

        let granted = state.roster.first { $0.definitionID == "igo" }
        XCTAssertNotNil(granted)
        XCTAssertEqual(granted?.level, LevelSystem.maxLevel)
        XCTAssertEqual(granted?.stars, StarFusionSystem.maxStars)

        XCTAssertFalse(state.purchase(item), "Exclusive character can't be bought twice")
        XCTAssertEqual(state.roster.count, startingRosterCount + 1, "Second attempt must not grant again")
    }

    func testExclusiveCharacterPurchasesAreIndependentPerCharacter() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let igo = ShopCatalog.exclusiveCharacters.first { $0.grantsDefinitionID == "igo" }!
        let ames = ShopCatalog.exclusiveCharacters.first { $0.grantsDefinitionID == "ames" }!

        XCTAssertTrue(state.purchase(igo))
        XCTAssertTrue(state.isPurchased(igo))
        XCTAssertFalse(state.isPurchased(ames), "Buying Igo must not mark Ames as purchased")
        XCTAssertTrue(state.canPurchase(ames))

        XCTAssertTrue(state.purchase(ames))
        XCTAssertTrue(state.isPurchased(ames))
        XCTAssertNotNil(state.roster.first { $0.definitionID == "igo" })
        XCTAssertNotNil(state.roster.first { $0.definitionID == "ames" })
    }
}
