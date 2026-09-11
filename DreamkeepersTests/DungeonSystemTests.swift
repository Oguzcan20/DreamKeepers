import XCTest
@testable import Dreamkeepers

final class DungeonSystemTests: XCTestCase {
    func testAllHasThreeDungeonsInLadderOrder() {
        XCTAssertEqual(DungeonSystem.all, [.whisperwood, .gloomvault, .starspire])
    }

    func testWavesProducesThreeWavesWithBossLast() {
        for id in DungeonID.allCases {
            let waves = DungeonSystem.waves(id)
            XCTAssertEqual(waves.count, DungeonSystem.waveCount)
            XCTAssertTrue(waves.dropLast().allSatisfy { !$0.isBoss })
            XCTAssertTrue(waves.last!.isBoss)
            XCTAssertNotNil(waves.last!.mechanic)
        }
    }

    func testPowerScalesEscalateAcrossTheLadder() {
        let whisperwoodBoss = DungeonSystem.waves(.whisperwood).last!
        let gloomvaultBoss = DungeonSystem.waves(.gloomvault).last!
        let starspireBoss = DungeonSystem.waves(.starspire).last!
        XCTAssertLessThan(whisperwoodBoss.maxHP, gloomvaultBoss.maxHP)
        XCTAssertLessThan(gloomvaultBoss.maxHP, starspireBoss.maxHP)
    }

    func testFirstClearRewardsEscalateAcrossTheLadder() {
        XCTAssertLessThan(DungeonSystem.firstClearGold(.whisperwood), DungeonSystem.firstClearGold(.gloomvault))
        XCTAssertLessThan(DungeonSystem.firstClearGold(.gloomvault), DungeonSystem.firstClearGold(.starspire))
        XCTAssertLessThan(DungeonSystem.firstClearGems(.whisperwood), DungeonSystem.firstClearGems(.gloomvault))
        XCTAssertLessThan(DungeonSystem.firstClearGems(.gloomvault), DungeonSystem.firstClearGems(.starspire))
    }

    func testFirstClearRarityIsAtLeastEpic() {
        for id in DungeonID.allCases {
            XCTAssertGreaterThanOrEqual(DungeonSystem.firstClearRarity(id), Rarity.epic)
        }
    }

    func testRepeatGoldIsFortyPercentOfFirstClearGold() {
        for id in DungeonID.allCases {
            let expected = Int((Double(DungeonSystem.firstClearGold(id)) * 0.4).rounded())
            XCTAssertEqual(DungeonSystem.repeatGold(id), expected)
        }
    }

    func testRecommendedLevelsEscalateAcrossTheLadder() {
        XCTAssertLessThan(DungeonSystem.recommendedLevel(.whisperwood), DungeonSystem.recommendedLevel(.gloomvault))
        XCTAssertLessThan(DungeonSystem.recommendedLevel(.gloomvault), DungeonSystem.recommendedLevel(.starspire))
    }

    // MARK: - GameState integration

    func testMakeDungeonBattleEngineConsumesAKeyAndBuildsAllWaves() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        // A fresh save's starter is deployed by default (see
        // `TeamSystemTests.testNewGameStartsWithExactlyOneTeamActiveAndDeployed`).
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let keysBefore = state.dungeonKeysRemainingToday
        guard let engine = state.makeDungeonBattleEngine(.whisperwood) else {
            return XCTFail("expected a dungeon battle engine")
        }
        XCTAssertEqual(state.dungeonKeysRemainingToday, keysBefore - 1)
        XCTAssertEqual(engine.totalWaves, DungeonSystem.waveCount)
        XCTAssertEqual(engine.currentWave, 1)
    }

    func testMakeDungeonBattleEngineFailsWithoutADeployedTeam() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.teams[0].memberIDs = []
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertNil(state.makeDungeonBattleEngine(.whisperwood))
    }

    func testApplyDungeonBattleResultGrantsFirstClearRewardsOnce() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertFalse(state.isDungeonCleared(.whisperwood))

        // A deliberately overwhelming player unit — dungeon enemies are
        // scaled well above a fresh Dreamkeeper's own stats, so a real
        // starter can't be relied on to win deterministically in a test.
        let overpoweredHero = Combatant(
            id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
            maxHP: 5000, currentHP: 5000, attack: 500, defense: 500, speed: 200, ultimate: nil
        )
        let waves = DungeonSystem.waves(.whisperwood)
        let engine = BattleEngine(
            playerUnits: [overpoweredHero], enemy: waves[0], stage: DungeonSystem.lootStage(.whisperwood),
            isBossStage: false, reinforcements: Array(waves.dropFirst())
        )
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 5000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }
        XCTAssertEqual(engine.outcome, .victory)

        let summary = state.applyDungeonBattleResult(from: engine, dungeon: .whisperwood)
        XCTAssertTrue(summary.isFirstClear)
        XCTAssertEqual(summary.goldGained, DungeonSystem.firstClearGold(.whisperwood))
        XCTAssertEqual(summary.gemsGained, DungeonSystem.firstClearGems(.whisperwood))
        XCTAssertNotNil(summary.droppedEquipment)
        XCTAssertTrue(state.isDungeonCleared(.whisperwood))
    }
}
