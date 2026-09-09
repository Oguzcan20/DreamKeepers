import XCTest
@testable import Dreamkeepers

final class AccountLevelTests: XCTestCase {
    private func winningEngine(stage: Int = 1) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 200, currentHP: 200, attack: 40, defense: 5, speed: 80, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: "Weakling", element: .ember, role: .damage, isPlayer: false, isBoss: false,
                               maxHP: 30, currentHP: 30, attack: 2, defense: 5, speed: 20, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: stage, isBossStage: false)
        engine.varianceProvider = { 1.0 }
        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }
        return engine
    }

    private func losingEngine(stage: Int = 1) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 10, currentHP: 10, attack: 1, defense: 0, speed: 20, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: "Titan", element: .ember, role: .damage, isPlayer: false, isBoss: false,
                               maxHP: 500, currentHP: 500, attack: 50, defense: 5, speed: 80, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: stage, isBossStage: false)
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

    func testAccountGainsExpOnVictory() {
        let state = makeState()
        XCTAssertEqual(state.save.playerExp, 0)

        _ = state.applyBattleResult(from: winningEngine())

        XCTAssertGreaterThan(state.save.playerExp, 0)
    }

    func testSingleEarlyWinDoesNotLevelUpAccountYet() {
        // Stage 1 accountExp (11) is well under the level-1 threshold (35),
        // so a single early win shouldn't report a level up.
        let state = makeState()
        let summary = state.applyBattleResult(from: winningEngine())

        XCTAssertNil(summary.accountLevelUp)
        XCTAssertEqual(state.save.playerLevel, 1)
    }

    func testAccountLevelsUpAfterEnoughWins() {
        let state = makeState()
        for _ in 0..<6 {
            _ = state.applyBattleResult(from: winningEngine())
        }

        XCTAssertGreaterThan(state.save.playerLevel, 1)
    }

    func testAccountLevelUpSummaryMatchesSaveWhenThresholdIsCrossed() {
        let state = makeState()
        var sawLevelUp = false
        for _ in 0..<10 {
            let summary = state.applyBattleResult(from: winningEngine())
            if let levelUp = summary.accountLevelUp {
                sawLevelUp = true
                XCTAssertEqual(levelUp.newLevel, state.save.playerLevel)
                XCTAssertLessThan(levelUp.oldLevel, levelUp.newLevel)
                break
            }
        }
        XCTAssertTrue(sawLevelUp, "Expected the account to level up within 10 wins")
    }

    func testAccountExpDoesNotAccrueOnDefeat() {
        let state = makeState()
        let summary = state.applyBattleResult(from: losingEngine())

        XCTAssertEqual(summary.outcome, .defeat)
        XCTAssertEqual(state.save.playerExp, 0)
        XCTAssertEqual(state.save.playerLevel, 1)
        XCTAssertNil(summary.accountLevelUp)
    }
}
