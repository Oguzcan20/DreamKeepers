import XCTest
@testable import Dreamkeepers

final class OlfStarterTests: XCTestCase {
    private func makeState() -> GameState {
        GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
    }

    // MARK: - Catalog shape

    func testAllSixOlfEntriesShareTheOlfFamily() {
        let olfIDs = ["olf_ember", "olf_tide", "olf_bloom", "olf_lunar", "olf_astral", "olf_ultimate"]
        for id in olfIDs {
            let def = DreamkeeperCatalog.starter.definition(for: id)
            XCTAssertEqual(def?.family, "olf", "\(id) must share the olf family for generalized fusion")
            XCTAssertEqual(def?.name, "Olf", "every Olf variant renders through the single shared Olf portrait")
        }
    }

    func testOnlyUltimateOlfIsExcludedFromSummoning() {
        for def in DreamkeeperCatalog.starter.definitions {
            if def.id == "olf_ultimate" {
                XCTAssertFalse(def.isSummonable, "Ultimate Olf must never be reachable via Summoning")
            } else {
                XCTAssertTrue(def.isSummonable, "\(def.id) should stay reachable via Summoning as normal")
            }
        }
    }

    func testUltimateOlfIsExactlyTenPercentStrongerThanTheNormalStarter() {
        let normal = DreamkeeperCatalog.starter.definition(for: "olf_ember")!
        let ultimate = DreamkeeperCatalog.starter.definition(for: "olf_ultimate")!

        XCTAssertEqual(ultimate.baseStats.hp, normal.baseStats.hp * 1.1, accuracy: 0.001)
        XCTAssertEqual(ultimate.baseStats.attack, normal.baseStats.attack * 1.1, accuracy: 0.001)
        XCTAssertEqual(ultimate.baseStats.defense, normal.baseStats.defense * 1.1, accuracy: 0.001)
        XCTAssertEqual(ultimate.baseStats.speed, normal.baseStats.speed * 1.1, accuracy: 0.001)

        XCTAssertEqual(ultimate.growthPerLevel.hp, normal.growthPerLevel.hp * 1.1, accuracy: 0.001)
        XCTAssertEqual(ultimate.growthPerLevel.attack, normal.growthPerLevel.attack * 1.1, accuracy: 0.001)
    }

    func testNeverRollsUltimateOlfEvenAtEveryRarityBand() {
        // Sweep a dense set of rolls across the whole [0, 1) range — Ultimate
        // Olf must never come back from any of them.
        for i in 0..<200 {
            let roll = Double(i) / 200.0
            let def = SummonSystem.rollDefinition(from: .starter, roll: roll)
            XCTAssertNotEqual(def.id, "olf_ultimate")
        }
    }

    // MARK: - Fresh save starts on the placeholder

    func testFreshSaveStartsWithThePlaceholderOlfAndNeedsAChoice() {
        let state = makeState()
        XCTAssertEqual(state.roster.first?.definitionID, DreamkeeperCatalog.starterOlfDefaultID)
        XCTAssertTrue(state.needsStarterOlfChoice)
    }

    // MARK: - Choosing an element

    func testChoosingAnElementSwapsTheSameInstanceInPlace() {
        let state = makeState()
        let starterID = state.roster.first!.id

        XCTAssertTrue(state.chooseStarterOlf(element: .tide))

        XCTAssertEqual(state.roster.count, 1, "the choice must not add a second roster entry")
        let starter = state.roster.first!
        XCTAssertEqual(starter.id, starterID, "the same instance carries over, not a fresh one")
        XCTAssertEqual(starter.definitionID, "olf_tide")
        XCTAssertFalse(state.needsStarterOlfChoice)
    }

    func testChoosingEmberResolvesNeedsStarterOlfChoice() {
        // Regression: `DreamkeeperCatalog.olfDefinitionID(for: .ember)` and
        // `starterOlfDefaultID` are both "olf_ember" — needsStarterOlfChoice
        // must be backed by a dedicated `hasChosenStarterElement` flag, not a
        // definitionID identity check, or choosing Ember would be a silent
        // no-op and the choice screen would reopen forever.
        let state = makeState()
        XCTAssertTrue(state.chooseStarterOlf(element: .ember))
        XCTAssertEqual(state.roster.first?.definitionID, "olf_ember")
        XCTAssertFalse(state.needsStarterOlfChoice)
    }

    func testChoosingIsANoOpOnceAlreadyResolved() {
        let state = makeState()
        XCTAssertTrue(state.chooseStarterOlf(element: .bloom))
        XCTAssertFalse(state.chooseStarterOlf(element: .lunar), "a second call must not silently re-pick the element")
        XCTAssertEqual(state.roster.first?.definitionID, "olf_bloom")
    }

    // MARK: - The secret gesture

    func testChoosingNilGrantsUltimateOlf() {
        let state = makeState()
        XCTAssertTrue(state.chooseStarterOlf(element: nil))
        XCTAssertEqual(state.roster.first?.definitionID, DreamkeeperCatalog.ultimateOlfID)
        XCTAssertFalse(state.needsStarterOlfChoice)
    }

    // MARK: - Generalized fusion across Olf variants

    func testAnyPulledOlfVariantCountsAsADuplicateOfTheStarter() {
        let state = makeState()
        _ = state.chooseStarterOlf(element: .ember)
        let starter = state.roster.first!

        // A different Olf variant, pulled from elsewhere, should still be
        // fusion fodder for the player's chosen starter Olf.
        let pulledAstralOlf = DreamkeeperInstance(definitionID: "olf_astral")
        state.debugSetRoster([starter, pulledAstralOlf])

        let dupes = state.duplicates(of: starter)
        XCTAssertEqual(dupes.map(\.id), [pulledAstralOlf.id])
    }

    func testFusingADifferentOlfVariantIntoTheStarterWorks() {
        let state = makeState()
        _ = state.chooseStarterOlf(element: .ember)
        let starter = state.roster.first!

        let fodder = (0..<4).map { _ in DreamkeeperInstance(definitionID: "olf_tide") }
        state.debugSetRoster([starter] + fodder)

        XCTAssertTrue(state.canFuseDreamkeeper(starter, consuming: fodder))
        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: fodder))

        let updated = state.roster.first { $0.id == starter.id }
        XCTAssertEqual(updated?.stars, 1)
        XCTAssertEqual(updated?.definitionID, "olf_ember", "fusing a different variant must not change the starter's own element")
    }

    func testNonOlfDreamkeepersStillRequireExactDefinitionMatch() {
        // Regression guard: the family generalization must not leak into
        // Dreamkeepers that don't declare a family at all.
        let state = makeState()
        let emberFox = DreamkeeperInstance(definitionID: "ember_fox")
        let moonHare = DreamkeeperInstance(definitionID: "moon_hare")
        state.debugSetRoster([emberFox, moonHare])

        XCTAssertTrue(state.duplicates(of: emberFox).isEmpty)
    }
}
