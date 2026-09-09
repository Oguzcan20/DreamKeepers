import XCTest
@testable import Dreamkeepers

final class OfflineRewardsTests: XCTestCase {
    func testPendingGoldScalesWithElapsedMinutes() {
        let tenMinutesAgo = Date().addingTimeInterval(-10 * 60)
        XCTAssertEqual(OfflineRewards.pendingGold(since: tenMinutesAgo), 10 * OfflineRewards.goldPerMinute)
    }

    func testPendingExpCapsAtEightHours() {
        let twoDaysAgo = Date().addingTimeInterval(-2 * 24 * 3600)
        let expected = Int(OfflineRewards.maxAccrualSeconds / 60 * Double(OfflineRewards.expPerMinute))
        XCTAssertEqual(OfflineRewards.pendingExp(since: twoDaysAgo), expected)
    }

    func testFutureTimestampNeverGoesNegative() {
        let future = Date().addingTimeInterval(60)
        XCTAssertEqual(OfflineRewards.pendingGold(since: future), 0)
    }

    func testCollectGoldFountainAddsGoldAndResetsTimer() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.lastGoldCollectedAt = Date().addingTimeInterval(-30 * 60)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let startingGold = state.save.gold
        let pending = state.pendingGoldFountainReward
        XCTAssertGreaterThan(pending, 0)

        let collected = state.collectGoldFountain()
        XCTAssertEqual(collected, pending)
        XCTAssertEqual(state.save.gold, startingGold + pending)
        XCTAssertEqual(state.pendingGoldFountainReward, 0)
    }

    func testCollectTrainingGardenRequiresDeployedTeam() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.teams[0].memberIDs = []
        seed.lastTrainingCollectedAt = Date().addingTimeInterval(-30 * 60)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertGreaterThan(state.pendingTrainingGardenReward, 0)
        XCTAssertNil(state.collectTrainingGarden())
    }

    func testCollectTrainingGardenGrantsExpToDeployedMembersOnly() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.lastTrainingCollectedAt = Date().addingTimeInterval(-60 * 60)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let starterID = state.roster[0].id
        let startingExp = state.roster[0].exp
        let startingLevel = state.roster[0].level

        let result = state.collectTrainingGarden()
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!.expGranted, 0)

        let updated = state.roster.first { $0.id == starterID }!
        XCTAssertTrue(updated.exp != startingExp || updated.level != startingLevel)
        XCTAssertEqual(state.pendingTrainingGardenReward, 0)
    }
}
