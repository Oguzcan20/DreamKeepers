import XCTest
@testable import Dreamkeepers

final class DailyMissionsTests: XCTestCase {
    /// `DailyMissions.drawDaily()` randomly picks 4 of the 7 free-tier
    /// missions per day, so a test asserting on one specific mission ID
    /// would only pass ~57% of the time (or crash on a force-unwrap) unless
    /// the draw is pinned. Setting today's date + the full pool as the
    /// selection short-circuits `ensureMissionsCurrent`'s redraw so every
    /// mission is guaranteed active.
    private func seedAllMissionsActive(_ seed: inout GameSave) {
        seed.dailyMissionDay = Calendar.current.startOfDay(for: Date())
        seed.dailyMissionSelectedIDs = DailyMissions.rotatingPool.map(\.rawValue)
    }

    /// A guaranteed-victory engine, independent of `makeBattleEngine()` /
    /// real catalog stats — mirrors the setup in BattleEngineTests.
    private func winningEngine(stage: Int = 1, isBossStage: Bool = false) -> BattleEngine {
        let hero = Combatant(id: UUID(), name: "Hero", element: .ember, role: .damage, isPlayer: true, isBoss: false,
                              maxHP: 200, currentHP: 200, attack: 40, defense: 5, speed: 80, ultimate: nil)
        let enemy = Combatant(id: UUID(), name: "Weakling", element: .ember, role: .damage, isPlayer: false, isBoss: isBossStage,
                               maxHP: 30, currentHP: 30, attack: 2, defense: 5, speed: 20, ultimate: nil)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: stage, isBossStage: isBossStage)
        engine.varianceProvider = { 1.0 }
        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }
        return engine
    }

    func testWinningABattleProgressesTheClearStageMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertEqual(state.dailyMissions.first { $0.id == .winBattle }?.progress, 0)

        let engine = winningEngine()
        XCTAssertEqual(engine.outcome, .victory)
        _ = state.applyBattleResult(from: engine)

        let mission = state.dailyMissions.first { $0.id == .winBattle }!
        XCTAssertEqual(mission.progress, 1)
        XCTAssertTrue(mission.isComplete)
        XCTAssertFalse(mission.isClaimed)
    }

    func testClaimGrantsRewardsOnceAndOnlyWhenComplete() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertFalse(state.claimMission(.performSummon), "Can't claim an incomplete mission")

        state.debugCompleteAllMissions()
        let startingGems = state.save.dreamGems
        XCTAssertTrue(state.claimMission(.performSummon))
        XCTAssertEqual(state.save.dreamGems, startingGems + DailyMissions.definitions.first { $0.id == .performSummon }!.gemReward)

        XCTAssertFalse(state.claimMission(.performSummon), "Can't claim the same mission twice")
    }

    func testMissionsResetOnANewDay() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.dailyMissionDay = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        seed.dailyMissionProgress = [MissionID.winBattle.rawValue: 1]
        seed.claimedMissionIDs = [MissionID.winBattle.rawValue]
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        // Triggers `ensureMissionsCurrent`'s day-rollover reset. Assert via
        // `save` directly rather than `dailyMissions.first { .winBattle }!`
        // — today's fresh draw is random and might not include winBattle.
        _ = state.dailyMissions
        XCTAssertEqual(state.save.dailyMissionProgress[MissionID.winBattle.rawValue] ?? 0, 0)
        XCTAssertFalse(state.save.claimedMissionIDs.contains(MissionID.winBattle.rawValue))
    }

    func testProgressNeverExceedsTarget() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        for _ in 0..<5 {
            _ = state.applyBattleResult(from: winningEngine())
        }

        let mission = state.dailyMissions.first { $0.id == .winBattle }!
        XCTAssertEqual(mission.progress, mission.definition.target)
    }

    func testClaimingTicketMissionsGrantsSummonTickets() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        seed.monsterSummonTickets = 0
        seed.equipmentSummonTickets = 0
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        state.debugCompleteAllMissions()

        XCTAssertTrue(state.claimMission(.defeatBoss))
        XCTAssertEqual(state.save.monsterSummonTickets, DailyMissions.definitions.first { $0.id == .defeatBoss }!.monsterTicketReward)

        XCTAssertTrue(state.claimMission(.upgradeEquipment))
        XCTAssertEqual(state.save.equipmentSummonTickets, DailyMissions.definitions.first { $0.id == .upgradeEquipment }!.equipmentTicketReward)
    }

    func testDefeatingABossProgressesTheDefeatBossMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertEqual(state.dailyMissions.first { $0.id == .defeatBoss }?.progress, 0)
        _ = state.applyBattleResult(from: winningEngine(isBossStage: true))
        XCTAssertEqual(state.dailyMissions.first { $0.id == .defeatBoss }?.progress, 1)
    }

    func testNonBossVictoryDoesNotProgressDefeatBossMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        _ = state.applyBattleResult(from: winningEngine(isBossStage: false))
        XCTAssertEqual(state.dailyMissions.first { $0.id == .defeatBoss }?.progress, 0)
    }

    func testUpgradingEquipmentProgressesTheUpgradeMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let item = EquipmentItem(slot: .weapon, name: "Test Blade", rarity: .common, level: 1,
                                  statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0))
        seed.inventory = [item]
        seed.gold = 1_000
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertTrue(state.upgradeEquipment(item))
        XCTAssertEqual(state.dailyMissions.first { $0.id == .upgradeEquipment }?.progress, 1)
    }

    func testShopPurchaseProgressesTheSpendInShopMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertTrue(state.purchase(ShopCatalog.gemPacks[0]))
        XCTAssertEqual(state.dailyMissions.first { $0.id == .spendInShop }?.progress, 1)
    }

    func testDeployingAFullTeamProgressesTheFieldTeamMission() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let extraInstances = DreamkeeperCatalog.unlockOrder.dropFirst(1).prefix(3).map { DreamkeeperInstance(definitionID: $0) }
        seed.roster.append(contentsOf: extraInstances)
        seed.teams[0].memberIDs = [] // starter auto-deploys on newGame(); reset so we control the toggles
        seedAllMissionsActive(&seed)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        XCTAssertEqual(state.dailyMissions.first { $0.id == .deployFullTeam }?.progress, 0)
        for instance in state.roster {
            state.toggleDeployed(instance)
        }
        XCTAssertEqual(state.deployedTeam.count, Team.maxSize)
        XCTAssertEqual(state.dailyMissions.first { $0.id == .deployFullTeam }?.progress, 1)
    }
}
