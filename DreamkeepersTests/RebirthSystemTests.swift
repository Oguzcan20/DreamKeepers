import XCTest
@testable import Dreamkeepers

final class RebirthSystemTests: XCTestCase {
    func testSoulPointsForFloorFlooredAtZeroAndFloorOne() {
        XCTAssertEqual(RebirthSystem.soulPointsForFloor(1), 0)
        XCTAssertEqual(RebirthSystem.soulPointsForFloor(5), 0)
        XCTAssertEqual(RebirthSystem.soulPointsForFloor(6), 1)
        XCTAssertEqual(RebirthSystem.soulPointsForFloor(50), 9)
        XCTAssertEqual(RebirthSystem.soulPointsForFloor(51), 10)
    }

    func testMaxRanksPerUpgrade() {
        XCTAssertEqual(RebirthSystem.maxRank(.goldFind), 10)
        XCTAssertEqual(RebirthSystem.maxRank(.expBoost), 10)
        XCTAssertEqual(RebirthSystem.maxRank(.damage), 10)
        XCTAssertEqual(RebirthSystem.maxRank(.offlineRewards), 5)
    }

    func testCostForRankScalesLinearlyWithBaseCost() {
        XCTAssertEqual(RebirthSystem.costForRank(.goldFind, 1), 2)
        XCTAssertEqual(RebirthSystem.costForRank(.goldFind, 2), 4)
        XCTAssertEqual(RebirthSystem.costForRank(.damage, 1), 3)
        XCTAssertEqual(RebirthSystem.costForRank(.offlineRewards, 1), 3)
    }

    func testEffectMultiplierAtRankZeroIsOne() {
        for upgrade in SoulUpgrade.allCases {
            XCTAssertEqual(RebirthSystem.effectMultiplier(upgrade, 0), 1.0, accuracy: 0.0001)
        }
    }

    func testEffectMultiplierAtMaxRank() {
        XCTAssertEqual(RebirthSystem.effectMultiplier(.goldFind, 10), 1.4, accuracy: 0.0001)
        XCTAssertEqual(RebirthSystem.effectMultiplier(.expBoost, 10), 1.4, accuracy: 0.0001)
        XCTAssertEqual(RebirthSystem.effectMultiplier(.damage, 10), 1.2, accuracy: 0.0001)
        XCTAssertEqual(RebirthSystem.effectMultiplier(.offlineRewards, 5), 1.5, accuracy: 0.0001)
    }

    func testEffectMultiplierClampsBeyondMaxRank() {
        XCTAssertEqual(
            RebirthSystem.effectMultiplier(.goldFind, 999),
            RebirthSystem.effectMultiplier(.goldFind, RebirthSystem.maxRank(.goldFind)),
            accuracy: 0.0001
        )
    }

    // MARK: - GameState integration

    func testPerformRebirthRequiresTheFloorRequirement() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.arenaFloor = RebirthSystem.rebirthFloorRequirement - 1
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertFalse(state.canRebirth)
        XCTAssertFalse(state.performRebirth())
        XCTAssertEqual(state.soulPoints, 0)
    }

    func testPerformRebirthGrantsSoulPointsAndResetsFloor() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.arenaFloor = RebirthSystem.rebirthFloorRequirement
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertTrue(state.canRebirth)
        let expectedPoints = state.pendingRebirthSoulPoints
        XCTAssertTrue(state.performRebirth())
        XCTAssertEqual(state.soulPoints, expectedPoints)
        XCTAssertEqual(state.rebirthCount, 1)
        XCTAssertEqual(state.save.arenaFloor, 1)
    }

    func testBuySoulUpgradeSpendsPointsAndIncreasesRank() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.soulPoints = 10
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertEqual(state.soulUpgradeRank(.goldFind), 0)
        XCTAssertTrue(state.buySoulUpgrade(.goldFind))
        XCTAssertEqual(state.soulUpgradeRank(.goldFind), 1)
        XCTAssertEqual(state.soulPoints, 8)
    }

    func testBuySoulUpgradeFailsWithoutEnoughPoints() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.soulPoints = 1
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertFalse(state.buySoulUpgrade(.goldFind))
        XCTAssertEqual(state.soulUpgradeRank(.goldFind), 0)
        XCTAssertEqual(state.soulPoints, 1)
    }
}
