import XCTest
@testable import Dreamkeepers

final class DreamkeeperCatalogTests: XCTestCase {
    func testCatalogHasSixtyEightUniqueDefinitions() {
        // 30 original + 30 second-wave + Igo/Ames (2) + Olf's 5 element variants + Ultimate Olf (1) = 68.
        let defs = DreamkeeperCatalog.starter.definitions
        XCTAssertEqual(defs.count, 68)
        XCTAssertEqual(Set(defs.map(\.id)).count, 68, "Definition ids must be unique")
    }

    func testEveryRarityOddsEntryHasAReachableCatalogDefinition() {
        for (rarity, _) in SummonSystem.rarityOdds {
            let matches = DreamkeeperCatalog.starter.definitions.filter { $0.rarity == rarity }
            XCTAssertFalse(matches.isEmpty, "\(rarity) is in rarityOdds but has no catalog entries — unreachable via summon")
        }
    }

    func testLegendaryTierIsReachableViaHighRoll() {
        // Cumulative thresholds from SummonSystem.rarityOdds: epic ends at
        // 0.985, legendary at 0.995, mythic at 1.0 — roll just inside the
        // legendary band so this still targets legendary specifically.
        let def = SummonSystem.rollDefinition(from: .starter, roll: 0.99)
        XCTAssertEqual(def.rarity, .legendary)
    }

    func testMythicTierIsReachableViaHighRoll() {
        let def = SummonSystem.rollDefinition(from: .starter, roll: 0.999)
        XCTAssertEqual(def.rarity, .mythic)
    }

    func testUnlockOrderEntriesAllExistInCatalog() {
        for id in DreamkeeperCatalog.unlockOrder {
            XCTAssertNotNil(DreamkeeperCatalog.starter.definition(for: id), "unlockOrder references missing id \(id)")
        }
    }

    func testNewRosterMembersAreSummonOnly() {
        let newIDs = ["thorn_viper", "tide_serpent", "ember_phoenix", "lunar_owl", "astral_sentinel", "coral_warden", "cinder_sprite"]
        for id in newIDs {
            XCTAssertNotNil(DreamkeeperCatalog.starter.definition(for: id))
            XCTAssertFalse(DreamkeeperCatalog.unlockOrder.contains(id), "\(id) should only be reachable via the Dream Shrine, not free boss recruits")
        }
    }
}
