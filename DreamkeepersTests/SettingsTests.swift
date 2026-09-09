import XCTest
@testable import Dreamkeepers

final class SettingsTests: XCTestCase {
    func testHapticsAreEnabledByDefaultOnANewSave() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        XCTAssertTrue(state.hapticsEnabled)
    }

    func testDisablingHapticsSuppressesPlatformCalls() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.setHapticsEnabled(false)
        state.playHaptic(.success)

        XCTAssertEqual(platform.hapticCallCount, 0)
    }

    func testEnabledHapticsReachThePlatform() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.playHaptic(.success)

        XCTAssertEqual(platform.hapticCallCount, 1)
    }

    func testHapticsPreferencePersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        state.setHapticsEnabled(false)

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertFalse(reloaded.hapticsEnabled)
    }

    func testSoundIsEnabledByDefaultOnANewSave() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        XCTAssertTrue(state.soundEnabled)
    }

    func testDisablingSoundSuppressesPlatformCalls() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.setSoundEnabled(false)
        state.playSound(.summon)

        XCTAssertEqual(platform.soundCallCount, 0)
    }

    func testEnabledSoundReachesThePlatform() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.playSound(.summon)

        XCTAssertEqual(platform.soundCallCount, 1)
    }

    func testSoundPreferencePersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        state.setSoundEnabled(false)

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertFalse(reloaded.soundEnabled)
    }

    func testHapticsAndSoundAreGatedIndependently() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.setHapticsEnabled(false)
        state.playHaptic(.levelUp) // haptics off, but this style has a paired sound

        XCTAssertEqual(platform.hapticCallCount, 0)
        XCTAssertEqual(platform.soundCallCount, 1)
    }

    func testPlayHapticFiresItsPairedSoundAutomatically() {
        let platform = MockPlatformService()
        let state = GameState(platform: platform, saveSystem: InMemorySaveSystem())

        state.playHaptic(.warning) // no paired sound for warning

        XCTAssertEqual(platform.hapticCallCount, 1)
        XCTAssertEqual(platform.soundCallCount, 0)
    }

    func testResetProgressRestoresAFreshSave() {
        let saveSystem = InMemorySaveSystem()
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertTrue(state.purchase(ShopCatalog.starterPack))
        XCTAssertGreaterThan(state.save.gold, 100)

        state.resetProgress()

        XCTAssertEqual(state.save.gold, 100)
        XCTAssertEqual(state.save.dreamGems, 50)
        XCTAssertEqual(state.roster.count, 1)
        XCTAssertEqual(state.save.currentStage, 1)
    }

    func testLanguageDefaultsToFollowingTheSystemLocale() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        XCTAssertNil(state.preferredLanguage)
        XCTAssertEqual(state.preferredLocale, .autoupdatingCurrent)
    }

    func testSettingGermanOverridesTheLocale() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        state.setPreferredLanguage("de")

        XCTAssertEqual(state.preferredLanguage, "de")
        XCTAssertEqual(state.preferredLocale.identifier, "de")
    }

    func testLanguagePreferencePersistsAcrossReload() {
        let saveSystem = InMemorySaveSystem()
        let state = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        state.setPreferredLanguage("de")

        let reloaded = GameState(platform: MockPlatformService(), saveSystem: saveSystem)
        XCTAssertEqual(reloaded.preferredLanguage, "de")
    }

    func testSwitchingBackToEnglishClearsTheGermanOverride() {
        let state = GameState(platform: MockPlatformService(), saveSystem: InMemorySaveSystem())
        state.setPreferredLanguage("de")
        state.setPreferredLanguage("en")

        XCTAssertEqual(state.preferredLanguage, "en")
        XCTAssertEqual(state.preferredLocale.identifier, "en")
    }
}
