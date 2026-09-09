import Foundation

/// One seam for rewarded-video ads, mirroring how `PlatformService` isolates
/// the rest of the OS. No ad network is wired in yet — shipping this for
/// real needs an AdMob (or similar) account, an app-level ad unit ID, and
/// the network's SDK added as a dependency; `GameState`, `DreamHavenView`,
/// and every other call site are already written against this protocol, so
/// swapping `MockAdRewardService` for a real `AdMobRewardService` later is a
/// one-line change at the `GameState` init call site, nothing more. `async`
/// rather than a completion handler so the actor-isolation hop back to the
/// main actor (every call site is UI-driven) is handled by the language,
/// not by hand-annotating captured closures.
///
///     AdRewardService
///      ├── MockAdRewardService   (active — simulates the ad, always pays out)
///      └── AdMobRewardService    (future, once a real ad account exists)
protocol AdRewardService {
    /// Presents a rewarded-video ad and returns whether the viewer watched
    /// it through to the reward. A real implementation would also return
    /// `false` when no ad is available to fill.
    @MainActor
    func showRewardedAd() async -> Bool
}

/// Development placeholder: simulates the few seconds a real rewarded ad
/// takes to play, then always reports success. Lets the entire reward-grant
/// flow (cooldown, currency grant, VIP gating) be built and tested end to
/// end today, with no ad network dependency and no real ad content shown.
struct MockAdRewardService: AdRewardService {
    @MainActor
    func showRewardedAd() async -> Bool {
        try? await Task.sleep(nanoseconds: 2_500_000_000)
        return true
    }
}
