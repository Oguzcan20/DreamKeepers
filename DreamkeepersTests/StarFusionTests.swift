import XCTest
@testable import Dreamkeepers

final class StarFusionTests: XCTestCase {
    // MARK: - StarFusionSystem (pure math)

    func testDuplicatesRequiredGrowsByFourPerTier() {
        XCTAssertEqual(StarFusionSystem.duplicatesRequired(forTier: 1), 4)
        XCTAssertEqual(StarFusionSystem.duplicatesRequired(forTier: 2), 8)
        XCTAssertEqual(StarFusionSystem.duplicatesRequired(forTier: 3), 12)
        XCTAssertEqual(StarFusionSystem.duplicatesRequired(forTier: 4), 16)
        XCTAssertEqual(StarFusionSystem.duplicatesRequired(forTier: 5), 20)
    }

    func testCannotFuseWithoutEnoughDuplicates() {
        XCTAssertFalse(StarFusionSystem.canFuse(stars: 0, duplicatesOwned: 3))
        XCTAssertTrue(StarFusionSystem.canFuse(stars: 0, duplicatesOwned: 4))
    }

    func testCannotFuseBeyondMaxStars() {
        XCTAssertFalse(StarFusionSystem.canFuse(stars: StarFusionSystem.maxStars, duplicatesOwned: 999))
    }

    // MARK: - Dreamkeeper stat integration

    func testZeroStarsGrantsNoStarBonus() {
        let def = DreamkeeperCatalog.starter.definitions.first!
        let unstarred = DreamkeeperInstance(definitionID: def.id, stars: 0)
        let onestar = DreamkeeperInstance(definitionID: def.id, stars: 1)

        let statsAt0 = unstarred.currentStats(in: .starter)
        let statsAt1 = onestar.currentStats(in: .starter)

        XCTAssertGreaterThan(statsAt1.attack, statsAt0.attack)
    }

    // MARK: - GameState integration (manual, instance-based fusion)

    private func makeState() -> GameState {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        return GameState(platform: MockPlatformService(), saveSystem: saveSystem)
    }

    func testFreshDreamkeeperStartsAtZeroStarsWithNoDuplicates() {
        let state = makeState()
        let starter = state.roster.first!
        XCTAssertEqual(starter.stars, 0)
        XCTAssertTrue(state.duplicates(of: starter).isEmpty)
    }

    func testDuplicateSummonBecomesARealRosterInstanceNotAnAutoStar() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed.dreamGems = 5_000
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        var sawDuplicate = false
        for _ in 0..<40 {
            guard state.canAffordSummon, let result = state.performSummon() else { break }
            if !result.isNew {
                sawDuplicate = true
                let target = state.roster.first { $0.definitionID == result.definition.id }!
                XCTAssertGreaterThan(state.duplicates(of: target).count, 0)
                XCTAssertEqual(target.stars, 0, "stars must not auto-advance from a duplicate pull")
                break
            }
        }
        XCTAssertTrue(sawDuplicate, "Expected at least one duplicate pull across many summons")
    }

    func testCannotFuseWithoutEnoughSelectedDuplicates() {
        let state = makeState()
        let starter = state.roster.first!
        XCTAssertFalse(state.canFuseDreamkeeper(starter, consuming: []))
        XCTAssertFalse(state.fuseDreamkeeper(starter, consuming: []))
    }

    func testFusingWithMoreThanRequiredCarriesOverRemainder() {
        let state = makeState()
        state.debugSeedDuplicates(5)
        let starter = state.roster.first!
        let allFive = state.duplicates(of: starter)
        XCTAssertEqual(allFive.count, 5)

        // Tier 1 costs 4 — selecting all 5 now succeeds (no exact-match
        // requirement) and banks the extra 1 toward tier 2.
        XCTAssertTrue(state.canFuseDreamkeeper(starter, consuming: allFive))
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: allFive))

        let updated = state.roster.first { $0.id == starter.id }
        XCTAssertEqual(updated?.stars, 1)
        XCTAssertEqual(updated?.fusionProgress, 1)
    }

    func testFusingFewerThanRequiredBanksProgressWithoutStarUp() {
        let state = makeState()
        state.debugSeedDuplicates(3)
        let starter = state.roster.first!
        let selected = state.duplicates(of: starter)
        XCTAssertEqual(selected.count, 3)

        // Always fuse-able, even short of the tier's full cost — it just
        // banks progress instead of being rejected outright.
        XCTAssertTrue(state.canFuseDreamkeeper(starter, consuming: selected))
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: selected))

        let updated = state.roster.first { $0.id == starter.id }
        XCTAssertEqual(updated?.stars, 0, "3 of 4 needed shouldn't star up yet")
        XCTAssertEqual(updated?.fusionProgress, 3)
        XCTAssertTrue(state.duplicates(of: starter).isEmpty, "the 3 selected duplicates are consumed even though no star was granted")
    }

    func testBankedFusionProgressAccumulatesAcrossMultipleFuses() {
        let state = makeState()
        state.debugSeedDuplicates(3)
        let starter = state.roster.first!
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: state.duplicates(of: starter))) // banks 3

        state.debugSeedDuplicates(1)
        let secondBatch = state.duplicates(of: starter)
        XCTAssertEqual(secondBatch.count, 1)
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: secondBatch)) // 3 + 1 = 4 -> tier 1

        let updated = state.roster.first { $0.id == starter.id }
        XCTAssertEqual(updated?.stars, 1)
        XCTAssertEqual(updated?.fusionProgress, 0)
    }

    func testCannotFuseUsingAnotherSpeciesAsFodder() {
        let state = makeState()
        state.debugSeedDuplicates(4)
        let starter = state.roster.first!

        // Summon a guaranteed-different species by rolling directly into the roster.
        let otherDefinition = state.catalog.definitions.first { $0.id != starter.definitionID }!
        let impostor = DreamkeeperInstance(definitionID: otherDefinition.id)

        XCTAssertFalse(state.canFuseDreamkeeper(starter, consuming: [impostor]))
    }

    func testFusingConsumesSelectedDuplicatesAndAdvancesOneStar() {
        let state = makeState()
        state.debugSeedDuplicates(4)
        let starter = state.roster.first!
        let selected = state.duplicates(of: starter)
        XCTAssertEqual(selected.count, 4)

        XCTAssertTrue(state.canFuseDreamkeeper(starter, consuming: selected))
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: selected))

        let updated = state.roster.first { $0.id == starter.id }
        XCTAssertEqual(updated?.stars, 1)
        for consumed in selected {
            XCTAssertFalse(state.roster.contains { $0.id == consumed.id })
        }
        XCTAssertEqual(state.roster.count, 1, "the 4 consumed duplicates should be gone, leaving only the fused target")
    }

    func testFusingBenchesAConsumedDuplicateThatWasDeployed() {
        let state = makeState()
        state.debugSeedDuplicates(4)
        let starter = state.roster.first!
        let selected = state.duplicates(of: starter)
        let extraSlot = selected.first!
        state.toggleDeployed(extraSlot) // deploy one of the fusion-fodder copies

        XCTAssertTrue(state.isDeployed(extraSlot))
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: selected))

        XCTAssertFalse(state.save.teams[0].memberIDs.contains(extraSlot.id))
    }

    func testFusionPersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        state.debugSeedDuplicates(4)
        let starter = state.roster.first!
        _ = state.fuseDreamkeeper(starter, consuming: state.duplicates(of: starter))

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertEqual(reloaded.roster.first?.stars, 1)
        XCTAssertEqual(reloaded.roster.count, 1)
    }

    func testOwnedSpeciesCountIgnoresDuplicates() {
        let state = makeState()
        XCTAssertEqual(state.ownedSpeciesCount, 1)

        state.debugSeedDuplicates(3)

        XCTAssertEqual(state.roster.count, 4)
        XCTAssertEqual(state.ownedSpeciesCount, 1, "duplicates must not inflate the distinct-species count")
    }

    // MARK: - Equipment star fusion

    private func makeItem(stars: Int = 0) -> EquipmentItem {
        EquipmentItem(slot: .weapon, name: "Ember Dagger", rarity: .rare, level: 1,
                      statBonus: Stats(hp: 0, attack: 10, defense: 0, speed: 0), stars: stars)
    }

    func testZeroStarItemGrantsNoBonusOverBase() {
        let item = makeItem(stars: 0)
        XCTAssertEqual(item.effectiveStatBonus.attack, item.statBonus.attack, accuracy: 0.001)
    }

    func testItemStarsIncreaseEffectiveStatBonus() {
        let base = makeItem(stars: 0)
        let starred = makeItem(stars: 1)
        XCTAssertGreaterThan(starred.effectiveStatBonus.attack, base.effectiveStatBonus.attack)
    }

    func testItemsOfDifferentSlotAreNotTheSameKind() {
        let weapon = makeItem()
        var ring = weapon
        ring.slot = .ring
        XCTAssertFalse(weapon.isSameKind(as: ring))
    }

    func testItemsWithDifferentLevelsAreStillTheSameKind() {
        let a = makeItem()
        var b = a
        b.level = 5
        b.id = UUID()
        XCTAssertTrue(a.isSameKind(as: b))
    }

    func testCannotFuseItemWithoutEnoughDuplicates() {
        let state = makeState()
        let target = makeItem()
        state.debugSetInventory([target])
        XCTAssertFalse(state.canFuseItem(target, consuming: []))
    }

    func testFusingItemConsumesSelectedDuplicatesAndAdvancesOneStar() {
        let state = makeState()
        let target = makeItem()
        let duplicates = (0..<4).map { _ in makeItem() }
        state.debugSetInventory([target] + duplicates)

        XCTAssertEqual(state.duplicates(ofItem: target).count, 4)
        XCTAssertTrue(state.canFuseItem(target, consuming: duplicates))
        XCTAssertTrue(state.fuseItem(target, consuming: duplicates))

        let updated = state.inventory.first { $0.id == target.id }
        XCTAssertEqual(updated?.stars, 1)
        XCTAssertEqual(state.inventory.count, 1, "the 4 consumed duplicates should be gone, leaving only the fused target")
    }

    func testFusingItemUnequipsAConsumedDuplicateThatWasWorn() {
        let state = makeState()
        let target = makeItem()
        let duplicates = (0..<4).map { _ in makeItem() }
        state.debugSetInventory([target] + duplicates)
        let wornDuplicate = duplicates[0]
        state.equip(wornDuplicate, to: state.roster.first!)

        XCTAssertEqual(state.wearer(of: wornDuplicate)?.id, state.roster.first!.id)
        XCTAssertTrue(state.fuseItem(target, consuming: duplicates))

        XCTAssertNil(state.equippedItem(.weapon, for: state.roster.first!))
    }

    func testItemFusionPersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        let target = makeItem()
        let duplicates = (0..<4).map { _ in makeItem() }
        state.debugSetInventory([target] + duplicates)
        _ = state.fuseItem(target, consuming: duplicates)

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertEqual(reloaded.inventory.first?.stars, 1)
        XCTAssertEqual(reloaded.inventory.count, 1)
    }
}
