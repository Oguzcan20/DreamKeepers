import XCTest
@testable import Dreamkeepers

final class TeamSystemTests: XCTestCase {
    private func makeState() -> GameState {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        return GameState(platform: MockPlatformService(), saveSystem: saveSystem)
    }

    func testNewGameStartsWithExactlyOneTeamActiveAndDeployed() {
        let state = makeState()
        XCTAssertEqual(state.teams.count, 1)
        XCTAssertEqual(state.activeTeamID, state.teams[0].id)
        XCTAssertEqual(state.deployedTeam.count, 1)
    }

    func testCreateTeamAddsANewEmptyTeamUpToFive() {
        let state = makeState()
        for _ in 0..<4 {
            XCTAssertNotNil(state.createTeam())
        }
        XCTAssertEqual(state.teams.count, 5)
        XCTAssertNil(state.createTeam(), "a 6th team should be rejected")
        XCTAssertEqual(state.teams.count, 5)
    }

    func testNewTeamStartsWithNoMembers() {
        let state = makeState()
        let newTeam = state.createTeam()
        XCTAssertEqual(newTeam?.memberIDs.isEmpty, true)
    }

    func testSetActiveTeamSwitchesWhichTeamIsDeployed() {
        let state = makeState()
        let starter = state.roster.first!
        guard let secondTeam = state.createTeam() else { return XCTFail("expected a second team") }

        // Starter is deployed on the first (default-active) team.
        XCTAssertTrue(state.isDeployed(starter))

        state.setActiveTeam(secondTeam.id)
        XCTAssertEqual(state.activeTeamID, secondTeam.id)
        XCTAssertFalse(state.isDeployed(starter), "starter belongs to the first team, not the newly active one")
        XCTAssertTrue(state.deployedTeam.isEmpty)
    }

    func testTogglingDeployedOnlyAffectsTheActiveTeam() {
        let state = makeState()
        let starter = state.roster.first!
        guard let secondTeam = state.createTeam() else { return XCTFail("expected a second team") }

        state.setActiveTeam(secondTeam.id)
        state.toggleDeployed(starter)
        XCTAssertTrue(state.isDeployed(starter))
        XCTAssertEqual(state.deployedTeam.map(\.id), [starter.id])

        state.setActiveTeam(state.teams[0].id)
        XCTAssertTrue(state.isDeployed(starter), "starter was already deployed on the first team from newGame()")
    }

    func testSetActiveTeamIgnoresUnknownID() {
        let state = makeState()
        let originalActive = state.activeTeamID
        state.setActiveTeam(UUID())
        XCTAssertEqual(state.activeTeamID, originalActive)
    }

    func testFusingConsumedDuplicatesRemovesThemFromEveryTeamNotJustActive() {
        let state = makeState()
        state.debugSeedDuplicates(4)
        let starter = state.roster.first!
        let selected = state.duplicates(of: starter)
        let extraSlot = selected.first!

        // Deploy the fusion-fodder copy onto a *second* team, then switch away from it.
        guard let secondTeam = state.createTeam() else { return XCTFail("expected a second team") }
        state.setActiveTeam(secondTeam.id)
        state.toggleDeployed(extraSlot)
        XCTAssertTrue(state.isDeployed(extraSlot))
        state.setActiveTeam(state.teams[0].id)

        XCTAssertTrue(state.fuseDreamkeeper(starter, consuming: selected))

        XCTAssertFalse(state.teams[0].memberIDs.contains(extraSlot.id))
        XCTAssertFalse(state.teams[1].memberIDs.contains(extraSlot.id))
    }

    func testTeamsAndActiveTeamPersistAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let seed = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        try? saveSystem.save(seed)
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)

        guard let secondTeam = state.createTeam() else { return XCTFail("expected a second team") }
        state.setActiveTeam(secondTeam.id)

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertEqual(reloaded.teams.count, 2)
        XCTAssertEqual(reloaded.activeTeamID, secondTeam.id)
    }

    func testLegacySingleTeamSaveMigratesIntoTeamsArray() throws {
        // Simulates a save written before the multi-team system existed:
        // only a `team` key, no `teams`/`activeTeamID`.
        let starter = DreamkeeperInstance(definitionID: DreamkeeperCatalog.unlockOrder[0])
        let legacyTeam = Team(name: "Main Team", memberIDs: [starter.id])
        let encoder = JSONEncoder()
        let rosterData = try encoder.encode([starter])
        let teamData = try encoder.encode(legacyTeam)

        // Build the legacy JSON payload by hand so this test is independent
        // of whatever GameSave.encode(to:) currently writes.
        var json: [String: Any] = [
            "playerLevel": 1, "playerExp": 0, "gold": 100, "dreamGems": 50,
            "roster": try JSONSerialization.jsonObject(with: rosterData),
            "team": try JSONSerialization.jsonObject(with: teamData),
            "inventory": [], "currentStage": 1,
            "lastGoldCollectedAt": ISO8601DateFormatter().string(from: Date()),
            "lastTrainingCollectedAt": ISO8601DateFormatter().string(from: Date()),
            "dailyMissionDay": ISO8601DateFormatter().string(from: Date.distantPast),
            "dailyMissionProgress": [:], "claimedMissionIDs": [], "purchasedOneTimeOfferIDs": [],
        ]
        let payload = try JSONSerialization.data(withJSONObject: json)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let migrated = try decoder.decode(GameSave.self, from: payload)

        XCTAssertEqual(migrated.teams.count, 1)
        XCTAssertEqual(migrated.teams[0].memberIDs, [starter.id])
        XCTAssertEqual(migrated.activeTeamID, migrated.teams[0].id)
    }
}
