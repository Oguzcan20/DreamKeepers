import XCTest
@testable import Dreamkeepers

final class CloudSaveStoreTests: XCTestCase {
    /// The test sandbox / CI has no signed-in iCloud account, so
    /// `cloudFileURL` is nil and every call degrades to the local copy —
    /// exactly the "iCloud unavailable" path real devices without iCloud
    /// enabled would hit too.
    func testGracefullyFallsBackToLocalWhenICloudIsUnavailable() {
        let platform = MockPlatformService()
        let store = CloudSaveStore(platform: platform)
        let save = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])

        XCTAssertNoThrow(try store.save(save))
        let loaded = store.load()

        XCTAssertEqual(loaded?.roster.first?.definitionID, save.roster.first?.definitionID)
        XCTAssertEqual(loaded?.gold, save.gold)
    }

    func testLoadReturnsNilWhenNothingHasBeenSavedYet() {
        let platform = MockPlatformService()
        // Fresh, never-used storage directory so no stale save.json exists.
        let scratchDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: scratchDir, withIntermediateDirectories: true)
        platform.appStorageDirectoryOverride = scratchDir

        let store = CloudSaveStore(platform: platform)
        XCTAssertNil(store.load())
    }
}
