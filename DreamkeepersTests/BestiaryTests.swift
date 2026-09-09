import XCTest
@testable import Dreamkeepers

final class BestiaryTests: XCTestCase {
    private func winningEngine(enemyName: String = "Weakling", isBossStage: Bool = false) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 200, currentHP: 200, attack: 40, defense: 5, speed: 80, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: enemyName, element: .ember, role: .damage, isPlayer: false, isBoss: isBossStage,
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

    private func losingEngine(enemyName: String = "Titan") -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 10, currentHP: 10, attack: 1, defense: 0, speed: 20, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: enemyName, element: .ember, role: .damage, isPlayer: false, isBoss: false,
                               maxHP: 500, currentHP: 500, attack: 50, defense: 5, speed: 80, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
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

    func testMonstersAreUndiscoveredOnANewSave() {
        let state = makeState()
        XCTAssertFalse(state.isDiscovered("Bramble Stalker"))
        XCTAssertEqual(state.bestiaryDiscoveredCount, 0)
    }

    func testDefeatingAMonsterDiscoversIt() {
        let state = makeState()
        _ = state.applyBattleResult(from: winningEngine(enemyName: "Bramble Stalker"))

        // "Bramble Stalker" is World 1's roster, echoed by Worlds 11 and 21
        // (MonsterCatalog.sourceWorldID(for:)), so discovering it once counts
        // as 3 of `bestiaryTotalCount`'s per-world entries.
        XCTAssertTrue(state.isDiscovered("Bramble Stalker"))
        XCTAssertEqual(state.bestiaryDiscoveredCount, 3)
    }

    func testLosingABattleStillDiscoversTheEnemyEncountered() {
        let state = makeState()
        _ = state.applyBattleResult(from: losingEngine(enemyName: "Gloom Hound"))

        XCTAssertTrue(state.isDiscovered("Gloom Hound"))
    }

    func testDiscoveryPersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        _ = state.applyBattleResult(from: winningEngine(enemyName: "Bramble Stalker"))

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertTrue(reloaded.isDiscovered("Bramble Stalker"))
    }

    func testBestiaryTotalCountMatchesSumOfEveryWorldsEntries() {
        let state = makeState()
        let expected = WorldCatalog.worlds.reduce(0) { $0 + MonsterCatalog.allEntries(forWorld: $1.id).count }
        XCTAssertEqual(state.bestiaryTotalCount, expected)
        XCTAssertGreaterThanOrEqual(state.bestiaryTotalCount, 270, "Expect roughly 270+ discoverable entries across all 30 worlds (10 rosters x 3 dreamings)")
    }

    func testResetProgressClearsDiscoveredMonsters() {
        let state = makeState()
        _ = state.applyBattleResult(from: winningEngine(enemyName: "Bramble Stalker"))
        XCTAssertEqual(state.bestiaryDiscoveredCount, 3) // echoed by Worlds 11 and 21 too

        state.resetProgress()

        XCTAssertEqual(state.bestiaryDiscoveredCount, 0)
        XCTAssertFalse(state.isDiscovered("Bramble Stalker"))
    }

    func testMonsterCatalogAllEntriesIncludesBossLast() {
        let entries = MonsterCatalog.allEntries(forWorld: 1)
        XCTAssertEqual(entries.count, 5)
        XCTAssertTrue(entries.last?.isBoss ?? false)
        XCTAssertEqual(entries.last?.name, "The Unraveling")
    }
}
