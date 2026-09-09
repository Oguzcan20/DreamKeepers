import XCTest
@testable import Dreamkeepers

final class MonsterCatalogTests: XCTestCase {
    func testEachWorldHasItsOwnRegularMonsterRoster() {
        let world1Names = Set((0..<4).map { MonsterCatalog.regularMonster(forWorld: 1, stage: $0).name })
        let world2Names = Set((0..<4).map { MonsterCatalog.regularMonster(forWorld: 2, stage: $0).name })
        let world3Names = Set((0..<4).map { MonsterCatalog.regularMonster(forWorld: 3, stage: $0).name })

        XCTAssertTrue(world1Names.isDisjoint(with: world2Names))
        XCTAssertTrue(world2Names.isDisjoint(with: world3Names))
        XCTAssertTrue(world1Names.isDisjoint(with: world3Names))
    }

    func testEachWorldBossHasAUniqueUltimate() {
        let names = (1...3).map { MonsterCatalog.boss(forWorld: $0).ultimate.name }
        XCTAssertEqual(Set(names).count, names.count, "Boss ultimates must not repeat across worlds")
    }

    func testUnknownWorldFallsBackSafelyInsteadOfCrashing() {
        let monster = MonsterCatalog.regularMonster(forWorld: 999, stage: 1)
        XCTAssertFalse(monster.name.isEmpty)
        let boss = MonsterCatalog.boss(forWorld: 999)
        XCTAssertFalse(boss.ultimate.name.isEmpty)
    }

    func testEnemyFactoryGivesBossesAWorldSpecificUltimateAndRegularsNone() {
        let bossCombatant = EnemyFactory.enemy(forStage: 5) // Whispering Meadow boss
        XCTAssertTrue(bossCombatant.isBoss)
        XCTAssertEqual(bossCombatant.ultimate?.name, MonsterCatalog.boss(forWorld: 1).ultimate.name)

        let regularCombatant = EnemyFactory.enemy(forStage: 2)
        XCTAssertFalse(regularCombatant.isBoss)
        XCTAssertNil(regularCombatant.ultimate)
    }

    func testDifferentWorldsProduceDifferentlyNamedBosses() {
        let boss1 = EnemyFactory.enemy(forStage: 5)
        let boss2 = EnemyFactory.enemy(forStage: 10)
        let boss3 = EnemyFactory.enemy(forStage: 15)
        XCTAssertEqual(Set([boss1.name, boss2.name, boss3.name]).count, 3)
        XCTAssertEqual(Set([boss1.ultimate?.name, boss2.ultimate?.name, boss3.ultimate?.name]).count, 3)
    }

    func testEachWorldBossHasItsSignatureMechanic() {
        XCTAssertEqual(MonsterCatalog.boss(forWorld: 1).mechanic, .selfHeal)
        XCTAssertEqual(MonsterCatalog.boss(forWorld: 2).mechanic, .enrage)
        XCTAssertEqual(MonsterCatalog.boss(forWorld: 3).mechanic, .shield)
    }

    func testEnemyFactoryGivesTheShieldBossItsInitialCharges() {
        let shieldBoss = EnemyFactory.enemy(forStage: 15) // Crystal Caverns boss
        XCTAssertEqual(shieldBoss.mechanic, .shield)
        XCTAssertEqual(shieldBoss.shieldCharges, 3)

        let selfHealBoss = EnemyFactory.enemy(forStage: 5) // Whispering Meadow boss
        XCTAssertEqual(selfHealBoss.mechanic, .selfHeal)
        XCTAssertEqual(selfHealBoss.shieldCharges, 0)
    }

    func testRegularMonstersHaveNoBossMechanic() {
        let regular = EnemyFactory.enemy(forStage: 2)
        XCTAssertNil(regular.mechanic)
    }

    // MARK: - World 4-10 expansion

    func testWorldCatalogHasThirtyWorldsAndOneHundredFiftyStages() {
        XCTAssertEqual(WorldCatalog.worlds.count, 30)
        XCTAssertEqual(WorldCatalog.totalStages, 150)
    }

    func testEveryWorldHasARegularRosterAndABossAsItsLastEntry() {
        for world in WorldCatalog.worlds {
            let entries = MonsterCatalog.allEntries(forWorld: world.id)
            XCTAssertFalse(entries.isEmpty, "World \(world.id) has no monster entries")
            XCTAssertTrue(entries.last?.isBoss ?? false, "World \(world.id)'s last entry must be its boss")
            XCTAssertEqual(entries.last?.name, world.bossName)
        }
    }

    func testAllThirtyBossesHaveUniqueNamesAndEveryMechanicTypeAppears() {
        let bossNames = WorldCatalog.worlds.map(\.bossName)
        XCTAssertEqual(Set(bossNames).count, 30, "Every world must have a unique boss name")

        // Worlds 11-30 reuse worlds 1-10's boss mechanic/lore/symbol (same
        // monster, stronger stats, per MonsterCatalog.sourceWorldID(for:)) —
        // so the set of mechanics used stays exactly the original 7 even
        // though 30 worlds share them.
        let mechanicsUsed = Set(WorldCatalog.worlds.map { MonsterCatalog.boss(forWorld: $0.id).mechanic })
        let allMechanics: Set<BossMechanic> = [.selfHeal, .enrage, .shield, .drain, .regenShield, .phaseShift, .sovereign]
        XCTAssertEqual(mechanicsUsed, allMechanics)
    }

    func testDifficultyMultiplierClimbsAcrossWorldTiers() {
        let byWorld = Dictionary(uniqueKeysWithValues: WorldCatalog.worlds.map { ($0.id, $0.difficultyMultiplier) })
        XCTAssertEqual(byWorld[1], 1.0)
        XCTAssertLessThan(byWorld[4]!, byWorld[6]!)
        XCTAssertLessThan(byWorld[6]!, byWorld[8]!)
        XCTAssertLessThan(byWorld[8]!, byWorld[9]!)
        XCTAssertLessThan(byWorld[9]!, byWorld[10]!)
        XCTAssertLessThan(byWorld[10]!, byWorld[11]!, "The second dreaming (world 11+) must be strictly harder than the first")
        XCTAssertLessThan(byWorld[11]!, byWorld[16]!)
        XCTAssertLessThan(byWorld[16]!, byWorld[20]!)
        XCTAssertLessThan(byWorld[20]!, byWorld[21]!, "The third dreaming (world 21+) must be strictly harder than the second")
        XCTAssertLessThan(byWorld[21]!, byWorld[26]!)
        XCTAssertLessThan(byWorld[26]!, byWorld[30]!)
    }

    func testNewWorldsReuseSourceWorldRostersAndBossMechanics() {
        // World 11 echoes World 1, World 21 echoes World 1 again — same
        // regular roster and boss mechanic/symbol/lore, but its own unique
        // boss name (from WorldCatalog) and far higher stats.
        for (echoID, sourceID) in [(11, 1), (21, 1), (16, 6), (30, 10)] {
            let echoRegulars = Set((0..<4).map { MonsterCatalog.regularMonster(forWorld: echoID, stage: $0).name })
            let sourceRegulars = Set((0..<4).map { MonsterCatalog.regularMonster(forWorld: sourceID, stage: $0).name })
            XCTAssertEqual(echoRegulars, sourceRegulars, "World \(echoID) should reuse World \(sourceID)'s regular roster")

            XCTAssertEqual(MonsterCatalog.boss(forWorld: echoID).mechanic, MonsterCatalog.boss(forWorld: sourceID).mechanic)
            XCTAssertEqual(MonsterCatalog.boss(forWorld: echoID).ultimate.name, MonsterCatalog.boss(forWorld: sourceID).ultimate.name)

            let echoWorld = WorldCatalog.worlds.first { $0.id == echoID }!
            let sourceWorld = WorldCatalog.worlds.first { $0.id == sourceID }!
            XCTAssertNotEqual(echoWorld.bossName, sourceWorld.bossName, "Each echoed world must still have its own boss name")
        }
    }

    func testEnemiesInLaterDreamingsAreStrongerThanTheSameStageOffsetInEarlierOnes() {
        // Stage 1 of World 11 (stage 51) vs. stage 1 of World 1 (stage 1) —
        // same source monster roster, but World 11's difficultyMultiplier
        // must make it noticeably stronger.
        let firstDreaming = EnemyFactory.enemy(forStage: 1)
        let secondDreaming = EnemyFactory.enemy(forStage: 51)
        let thirdDreaming = EnemyFactory.enemy(forStage: 101)
        XCTAssertGreaterThan(secondDreaming.attack, firstDreaming.attack)
        XCTAssertGreaterThan(thirdDreaming.attack, secondDreaming.attack)
    }

    func testLaterWorldEnemiesHitHarderThanEarlierOnesAtTheSameStageOffset() {
        // Stage 1 of World 1 vs. stage 1 of World 10 (stage 46).
        let earlyEnemy = EnemyFactory.enemy(forStage: 1)
        let lateEnemy = EnemyFactory.enemy(forStage: 46)
        XCTAssertGreaterThan(lateEnemy.attack, earlyEnemy.attack)
    }

    func testWorldSixMixesMultipleRarityTiersAmongRegulars() {
        // World 6 (Emberheart Wastes) is the densest roster (16 regulars) —
        // confirms rarity is actually varied, not a single flat default.
        let allEmber = (0..<16).map { MonsterCatalog.regularMonster(forWorld: 6, stage: $0).rarity }
        XCTAssertTrue(allEmber.contains(.common))
        XCTAssertTrue(allEmber.contains(.uncommon))
        XCTAssertTrue(allEmber.contains(.rare))
    }

    func testNameGeneratorIsDeterministicForTheSameSeed() {
        let first = MonsterCatalog.NameGenerator.generate(element: .ember, seed: 7)
        let second = MonsterCatalog.NameGenerator.generate(element: .ember, seed: 7)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }

    func testNameGeneratorVariesAcrossSeeds() {
        let names = Set((0..<10).map { MonsterCatalog.NameGenerator.generate(element: .astral, seed: $0) })
        XCTAssertGreaterThan(names.count, 1)
    }
}
