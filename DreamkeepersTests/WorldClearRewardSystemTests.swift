import XCTest
@testable import Dreamkeepers

final class WorldClearRewardSystemTests: XCTestCase {

    // MARK: - Pure reward-table math

    func testStandardWorldsPayFiftyGems() {
        // Worlds 1-4 each pay the standard amount.
        for world in 1...4 {
            XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: world), 50, "World \(world)")
        }
        // Worlds 6-9 pay the standard amount again, after the World 5 spike.
        for world in 6...9 {
            XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: world), 50, "World \(world)")
        }
    }

    func testEveryFifthWorldPaysTheMilestoneAmountInstead() {
        // Never additive — the milestone amount replaces the standard one on
        // that world only, it isn't 50 + 100.
        XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: 5), 100)
        XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: 10), 100)
        XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: 15), 100)
        XCTAssertEqual(WorldClearRewardSystem.gems(forCompletedWorld: 20), 100)
    }

    // MARK: - Wired into `GameState.applyBattleResult`

    private func makeState() -> GameState {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        return GameState(platform: MockPlatformService(), saveSystem: saveSystem)
    }

    private func winningEngine(stage: Int, isBoss: Bool) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 500, currentHP: 500, attack: 200, defense: 5, speed: 80, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: "Weakling", element: .ember, role: .damage, isPlayer: false, isBoss: isBoss,
                               maxHP: 30, currentHP: 30, attack: 2, defense: 5, speed: 20, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: stage, isBossStage: isBoss)
        engine.varianceProvider = { 1.0 }
        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }
        return engine
    }

    func testNonBossStageClearGrantsNoGems() {
        let state = makeState()
        let summary = state.applyBattleResult(from: winningEngine(stage: 1, isBoss: false))

        XCTAssertEqual(summary.gemsGained, 0)
        XCTAssertNil(summary.completedWorldNumber)
    }

    func testFirstBossClearGrantsStandardGemsAndReportsTheCompletedWorld() {
        let state = makeState()
        // `GameSave.newGame` seeds a starting Dream Gems balance, so every
        // assertion here is relative to that baseline rather than assuming
        // the save starts at zero.
        let startingGems = state.save.dreamGems
        // World 1 is stages 1-5 — clear the first four non-boss stages to
        // put the frontier at the boss stage, matching how the campaign is
        // actually played rather than jumping straight to stage 5.
        for stage in 1...4 {
            _ = state.applyBattleResult(from: winningEngine(stage: stage, isBoss: false))
        }
        XCTAssertEqual(state.save.dreamGems, startingGems, "Non-boss clears must not grant World-clear gems")

        let summary = state.applyBattleResult(from: winningEngine(stage: 5, isBoss: true))

        XCTAssertEqual(summary.gemsGained, 50)
        XCTAssertEqual(summary.completedWorldNumber, 1)
        XCTAssertEqual(state.save.dreamGems, startingGems + 50)
    }

    func testReplayingAnAlreadyClearedBossNeverRegrantsGems() {
        let state = makeState()
        let startingGems = state.save.dreamGems
        for stage in 1...4 {
            _ = state.applyBattleResult(from: winningEngine(stage: stage, isBoss: false))
        }
        _ = state.applyBattleResult(from: winningEngine(stage: 5, isBoss: true))
        XCTAssertEqual(state.save.dreamGems, startingGems + 50)

        // The frontier has moved on to stage 6 — fighting stage 5 again is a
        // replay, same `wasFrontierClear` gate the recruit grant already
        // relies on, and must not pay out a second time.
        let replaySummary = state.applyBattleResult(from: winningEngine(stage: 5, isBoss: true))

        XCTAssertEqual(replaySummary.gemsGained, 0)
        XCTAssertNil(replaySummary.completedWorldNumber)
        XCTAssertEqual(state.save.dreamGems, startingGems + 50)
    }

    func testFifthWorldBossClearGrantsTheMilestoneAmount() {
        let state = makeState()
        let startingGems = state.save.dreamGems
        // Fast-forward straight to World 5's boss frontier (stage 25) rather
        // than clearing 24 stages one at a time.
        state.debugSeedStage(25)

        let summary = state.applyBattleResult(from: winningEngine(stage: 25, isBoss: true))

        XCTAssertEqual(summary.gemsGained, 100)
        XCTAssertEqual(summary.completedWorldNumber, 5)
        XCTAssertEqual(state.save.dreamGems, startingGems + 100)
    }
}
