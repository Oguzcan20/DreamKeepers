import XCTest
@testable import Dreamkeepers

final class BattlePassTests: XCTestCase {
    private func winningEngine(isBossStage: Bool = false) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 200, currentHP: 200, attack: 40, defense: 5, speed: 80, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: "Weakling", element: .ember, role: .damage, isPlayer: false, isBoss: isBossStage,
                               maxHP: 30, currentHP: 30, attack: 2, defense: 5, speed: 20, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: isBossStage)
        engine.varianceProvider = { 1.0 }
        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }
        return engine
    }

    private func makeState() -> GameState {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        return GameState(platform: MockPlatformService(), saveSystem: saveSystem)
    }

    // MARK: - BattlePassSystem (pure math)

    func testTierZeroBeforeAnyXP() {
        XCTAssertEqual(BattlePassSystem.tier(forXP: 0), 0)
    }

    func testTierAdvancesEveryXPPerTier() {
        XCTAssertEqual(BattlePassSystem.tier(forXP: BattlePassSystem.xpPerTier), 1)
        XCTAssertEqual(BattlePassSystem.tier(forXP: BattlePassSystem.xpPerTier * 3), 3)
    }

    func testTierClampsAtTierCount() {
        let hugeXP = BattlePassSystem.xpPerTier * (BattlePassSystem.tierCount + 10)
        XCTAssertEqual(BattlePassSystem.tier(forXP: hugeXP), BattlePassSystem.tierCount)
    }

    func testPremiumRewardIsAlwaysAtLeastAsGoodAsFree() {
        for tier in 1...BattlePassSystem.tierCount {
            let free = BattlePassSystem.freeReward(forTier: tier)
            let premium = BattlePassSystem.premiumReward(forTier: tier)
            XCTAssertGreaterThanOrEqual(premium.gems, free.gems)
        }
    }

    // MARK: - GameState integration

    func testWinningABattleGrantsBattlePassXP() {
        let state = makeState()
        XCTAssertEqual(state.save.battlePassXP, 0)

        _ = state.applyBattleResult(from: winningEngine())

        XCTAssertEqual(state.save.battlePassXP, BattlePassSystem.xpGained(isBoss: false))
    }

    func testBossWinGrantsMoreBattlePassXPThanRegularWin() {
        XCTAssertGreaterThan(BattlePassSystem.xpGained(isBoss: true), BattlePassSystem.xpGained(isBoss: false))
    }

    func testCannotClaimRewardForUnreachedTier() {
        let state = makeState()
        XCTAssertFalse(state.canClaimBattlePassReward(tier: 1, premium: false))
    }

    func testClaimingFreeRewardGrantsGoldAndMarksClaimed() {
        let state = makeState()
        for _ in 0..<(BattlePassSystem.xpPerTier / BattlePassSystem.xpGained(isBoss: false) + 1) {
            _ = state.applyBattleResult(from: winningEngine())
        }
        XCTAssertGreaterThanOrEqual(state.battlePassTier, 1)

        let goldBefore = state.save.gold
        XCTAssertTrue(state.claimBattlePassReward(tier: 1, premium: false))

        XCTAssertGreaterThan(state.save.gold, goldBefore)
        XCTAssertTrue(state.isBattlePassRewardClaimed(tier: 1, premium: false))
        XCTAssertFalse(state.claimBattlePassReward(tier: 1, premium: false), "second claim should be rejected")
    }

    func testPremiumRewardIsLockedUntilPurchased() {
        let state = makeState()
        for _ in 0..<(BattlePassSystem.xpPerTier / BattlePassSystem.xpGained(isBoss: false) + 1) {
            _ = state.applyBattleResult(from: winningEngine())
        }

        XCTAssertFalse(state.canClaimBattlePassReward(tier: 1, premium: true))

        XCTAssertTrue(state.purchaseBattlePassPremium())
        XCTAssertTrue(state.canClaimBattlePassReward(tier: 1, premium: true))
    }

    func testPurchasingPremiumTwiceFails() {
        let state = makeState()
        XCTAssertTrue(state.purchaseBattlePassPremium())
        XCTAssertFalse(state.purchaseBattlePassPremium())
    }

    func testHasUnclaimedRewardsReflectsReachableTiers() {
        let state = makeState()
        XCTAssertFalse(state.hasUnclaimedBattlePassRewards)

        _ = state.applyBattleResult(from: winningEngine(isBossStage: false))
        for _ in 0..<10 {
            _ = state.applyBattleResult(from: winningEngine())
        }
        XCTAssertTrue(state.hasUnclaimedBattlePassRewards)

        while state.hasUnclaimedBattlePassRewards {
            var claimedSomething = false
            for tier in 1...state.battlePassTier {
                if state.claimBattlePassReward(tier: tier, premium: false) { claimedSomething = true }
            }
            if !claimedSomething { break }
        }
        XCTAssertFalse(state.hasUnclaimedBattlePassRewards)
    }

    func testBattlePassProgressPersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        _ = state.applyBattleResult(from: winningEngine())
        _ = state.purchaseBattlePassPremium()

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertEqual(reloaded.save.battlePassXP, state.save.battlePassXP)
        XCTAssertTrue(reloaded.battlePassPremiumUnlocked)
    }

    func testResetProgressClearsBattlePass() {
        let state = makeState()
        _ = state.applyBattleResult(from: winningEngine())
        _ = state.purchaseBattlePassPremium()

        state.resetProgress()

        XCTAssertEqual(state.save.battlePassXP, 0)
        XCTAssertFalse(state.battlePassPremiumUnlocked)
        XCTAssertEqual(state.battlePassTier, 0)
    }
}
