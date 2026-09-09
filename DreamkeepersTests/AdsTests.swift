import XCTest
@testable import Dreamkeepers

/// Covers the daily rewarded-ad cap and the automatic-interstitial pacing
/// logic in `GameState` — both exercised entirely through `MockAdRewardService`
/// / `MockInterstitialAdService` so no real ad network is ever touched.
final class AdsTests: XCTestCase {
    private func makeState(seed: (inout GameSave) -> Void = { _ in }) -> GameState {
        let saveSystem = InMemorySaveSystem()
        var save = GameSave.newGame(starterDefinitionID: DreamkeeperCatalog.unlockOrder[0])
        seed(&save)
        try? saveSystem.save(save)
        return GameState(
            platform: MockPlatformService(), saveSystem: saveSystem,
            adService: MockAdRewardService(), interstitialAdService: MockInterstitialAdService()
        )
    }

    // MARK: - Rewarded ad daily cap

    @MainActor
    func testRewardedAdGrantsCurrencyAndDecrementsDailyCount() async {
        let state = makeState()
        XCTAssertTrue(state.isRewardedAdAvailable)
        XCTAssertEqual(state.rewardedAdWatchesRemainingToday, GameState.maxRewardedAdsPerDay)

        let startingGold = state.save.gold
        let startingGems = state.save.dreamGems
        let rewarded = await state.watchRewardedAd()

        XCTAssertTrue(rewarded)
        XCTAssertEqual(state.save.gold, startingGold + GameState.rewardedAdGold)
        XCTAssertEqual(state.save.dreamGems, startingGems + GameState.rewardedAdGems)
        XCTAssertEqual(state.rewardedAdWatchesRemainingToday, GameState.maxRewardedAdsPerDay - 1)
    }

    @MainActor
    func testRewardedAdBlockedAfterDailyCapReached() async {
        let state = makeState()
        for _ in 0..<GameState.maxRewardedAdsPerDay {
            let rewarded = await state.watchRewardedAd()
            XCTAssertTrue(rewarded)
        }

        XCTAssertFalse(state.isRewardedAdAvailable)
        XCTAssertEqual(state.rewardedAdWatchesRemainingToday, 0)

        let goldBeforeExtra = state.save.gold
        let extraRewarded = await state.watchRewardedAd()
        XCTAssertFalse(extraRewarded, "A 4th watch the same day must be blocked")
        XCTAssertEqual(state.save.gold, goldBeforeExtra, "A blocked watch must not grant anything")
    }

    @MainActor
    func testVIPNeverSeesRewardedAdAvailable() async {
        let state = makeState { $0.isVIP = true }
        XCTAssertFalse(state.isRewardedAdAvailable)
        let rewarded = await state.watchRewardedAd()
        XCTAssertFalse(rewarded)
    }

    func testDailyCapResetsOnNewCalendarDay() {
        let state = makeState {
            $0.rewardedAdWatchDay = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            $0.rewardedAdWatchCount = GameState.maxRewardedAdsPerDay
        }
        XCTAssertEqual(state.rewardedAdWatchesRemainingToday, GameState.maxRewardedAdsPerDay, "A new calendar day resets the count")
        XCTAssertTrue(state.isRewardedAdAvailable)
    }

    // MARK: - Automatic interstitial pacing

    func testInterstitialNotShownBeforeStageThreshold() {
        let state = makeState { $0.stagesSinceLastInterstitial = GameState.stagesPerInterstitial - 1 }
        XCTAssertFalse(state.shouldShowInterstitial)
    }

    func testInterstitialShownAfterStageThresholdAndPacingFloor() {
        let state = makeState {
            $0.stagesSinceLastInterstitial = GameState.stagesPerInterstitial
            $0.lastInterstitialShownAt = .distantPast
        }
        XCTAssertTrue(state.shouldShowInterstitial)
    }

    func testInterstitialWithheldWithinPacingFloorEvenIfStageThresholdMet() {
        let state = makeState {
            $0.stagesSinceLastInterstitial = GameState.stagesPerInterstitial
            $0.lastInterstitialShownAt = Date()
        }
        XCTAssertFalse(state.shouldShowInterstitial, "Must respect the minimum time floor even once the stage count is high enough")
    }

    @MainActor
    func testShowingInterstitialResetsBothPacingCounters() async {
        let state = makeState {
            $0.stagesSinceLastInterstitial = GameState.stagesPerInterstitial
            $0.lastInterstitialShownAt = .distantPast
        }
        XCTAssertTrue(state.shouldShowInterstitial)
        await state.showInterstitialAd()
        XCTAssertFalse(state.shouldShowInterstitial)
        XCTAssertEqual(state.save.stagesSinceLastInterstitial, 0)
    }

    func testVIPNeverTriggersInterstitial() {
        let state = makeState {
            $0.isVIP = true
            $0.stagesSinceLastInterstitial = GameState.stagesPerInterstitial + 5
            $0.lastInterstitialShownAt = .distantPast
        }
        XCTAssertFalse(state.shouldShowInterstitial)
    }
}
