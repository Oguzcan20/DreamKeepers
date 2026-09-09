import XCTest
@testable import Dreamkeepers

final class TwinBondTests: XCTestCase {
    func testIsActiveOnlyWhenBothPresent() {
        XCTAssertFalse(TwinBond.isActive(memberDefinitionIDs: ["igo"]))
        XCTAssertFalse(TwinBond.isActive(memberDefinitionIDs: ["ames"]))
        XCTAssertFalse(TwinBond.isActive(memberDefinitionIDs: [DreamkeeperCatalog.unlockOrder[0]]))
        XCTAssertTrue(TwinBond.isActive(memberDefinitionIDs: ["igo", "ames"]))
        XCTAssertTrue(TwinBond.isActive(memberDefinitionIDs: ["ames", "igo", DreamkeeperCatalog.unlockOrder[0]]))
    }

    func testIsBondCharacterAndPartnerID() {
        XCTAssertTrue(TwinBond.isBondCharacter("igo"))
        XCTAssertTrue(TwinBond.isBondCharacter("ames"))
        XCTAssertFalse(TwinBond.isBondCharacter(DreamkeeperCatalog.unlockOrder[0]))
        XCTAssertEqual(TwinBond.partnerID(of: "igo"), "ames")
        XCTAssertEqual(TwinBond.partnerID(of: "ames"), "igo")
        XCTAssertNil(TwinBond.partnerID(of: DreamkeeperCatalog.unlockOrder[0]))
    }

    func testBattleEngineAppliesBondBonusOnlyWhenBothDeployed() {
        let saveSystem = InMemorySaveSystem()
        var seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        let igo = DreamkeeperInstance(definitionID: "igo", level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars)
        let ames = DreamkeeperInstance(definitionID: "ames", level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars)
        seed.roster.append(igo)
        seed.roster.append(ames)
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        let baseIgoStats = igo.currentStats(in: state.catalog, inventory: state.inventory)
        let baseAmesStats = ames.currentStats(in: state.catalog, inventory: state.inventory)

        // Baseline: neither Igo nor Ames is deployed yet (only the starter is).
        guard let baselineEngine = state.makeBattleEngine() else { return XCTFail("expected a battle engine") }
        XCTAssertNil(baselineEngine.playerUnits.first { $0.definitionID == "igo" })

        state.toggleDeployed(igo)
        state.toggleDeployed(ames)
        XCTAssertTrue(state.isDeployed(igo))
        XCTAssertTrue(state.isDeployed(ames))

        guard let bondedEngine = state.makeBattleEngine() else { return XCTFail("expected a battle engine") }
        guard let bondedIgo = bondedEngine.playerUnits.first(where: { $0.definitionID == "igo" }),
              let bondedAmes = bondedEngine.playerUnits.first(where: { $0.definitionID == "ames" }) else {
            return XCTFail("expected both Igo and Ames in the battle formation")
        }

        XCTAssertEqual(bondedIgo.attack, baseIgoStats.attack * 1.75, accuracy: 0.01)
        XCTAssertEqual(bondedIgo.defense, baseIgoStats.defense * 1.75, accuracy: 0.01)
        XCTAssertEqual(bondedAmes.attack, baseAmesStats.attack * 1.75, accuracy: 0.01)
        XCTAssertEqual(bondedAmes.defense, baseAmesStats.defense * 1.75, accuracy: 0.01)

        // Benching Ames must drop the bonus for both — Igo's own stats fall
        // straight back to baseline the next time an engine is built.
        state.toggleDeployed(ames)
        XCTAssertFalse(state.isDeployed(ames))
        guard let afterBenchEngine = state.makeBattleEngine() else { return XCTFail("expected a battle engine") }
        guard let afterBenchIgo = afterBenchEngine.playerUnits.first(where: { $0.definitionID == "igo" }) else {
            return XCTFail("expected Igo still in the battle formation")
        }
        XCTAssertEqual(afterBenchIgo.attack, baseIgoStats.attack, accuracy: 0.01)
        XCTAssertEqual(afterBenchIgo.defense, baseIgoStats.defense, accuracy: 0.01)
    }
}
