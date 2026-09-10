import Foundation
import GoogleMobileAds
import UIKit

/// Real rewarded-video ads via the Google Mobile Ads SDK — the production
/// counterpart to `MockAdRewardService`, conforming to the same
/// `AdRewardService` seam so nothing else in the app changes.
///
/// `GADApplicationIdentifier` in `project.yml` and `adUnitID` below are both
/// the real, live AdMob App ID / Rewarded ad unit ID for "DreamKeepers"
/// (registered 2026-09-03).
///
/// IMPORTANT — this is real, billable ad inventory now: repeatedly tapping
/// "Watch Ad" from a device that isn't registered as an AdMob test device
/// counts as real ad traffic. A handful of manual taps while confirming the
/// integration works is normal, but do not script/automate taps against
/// this ad unit (Simulator or device) — that pattern reads as invalid
/// traffic to Google and risks the AdMob account. Register real test
/// devices via `MobileAds.shared.requestConfiguration.testDeviceIdentifiers`
/// in `DreamkeepersApp.init()` (Google's SDK prints the device's identifier
/// to the console the first time it serves that device a real ad unit) if
/// repeated hands-on testing is needed.
final class AdMobRewardService: AdRewardService {
    /// Real Rewarded ad unit ID for "DreamKeepers", created in the AdMob
    /// console 2026-09-03. **Not used yet** — a brand-new ad unit on a
    /// brand-new AdMob app serves no fill until the app is live on the App
    /// Store with a matching store listing (and, for EEA users, a GDPR
    /// message configured for this app in the AdMob Privacy & messaging
    /// tab). Running it against the developer's own device before then is
    /// also invalid traffic. Swap `adUnitID` to this once the app ships —
    /// see the checklist in COMPLIANCE_CHECKLIST.md.
    static let realAdUnitID = "ca-app-pub-6011422497566268/5562733659"

    /// Google's publicly published iOS rewarded-ad **test unit**
    /// (https://developers.google.com/admob/ios/test-ads) — always 100%
    /// fill, never billable, not real traffic. This is what the Android
    /// (Flutter) port already uses, which is the whole reason ads work
    /// there and not here: the fix for "no ads on iPhone" is to test
    /// against the same test unit until launch, then flip to
    /// `realAdUnitID`.
    private let adUnitID = "ca-app-pub-3940256099942544/1712485313"

    /// `RewardedAd.fullScreenContentDelegate` is `weak` — nothing else keeps
    /// the delegate alive between "present" and "dismissed" (seconds later,
    /// while the viewer actually watches), so without a strong reference
    /// held somewhere for that whole window, ARC frees it right after
    /// `present(from:)` returns and the dismissal callback never fires,
    /// leaking the continuation below forever. This property is that
    /// reference.
    private var activeDelegate: RewardedAdDelegate?

    @MainActor
    func showRewardedAd() async -> Bool {
        guard let rootViewController = UIApplication.dk_rootViewController else { return false }

        AdLog.logRequestReadiness(context: "rewarded load")

        let ad: RewardedAd
        do {
            ad = try await RewardedAd.load(with: adUnitID, request: Request())
        } catch {
            // No fill / network error / misconfigured ad unit — reported
            // the same as a declined ad rather than crashing the flow.
            AdLog.log("rewarded load FAILED: \((error as NSError).domain)#\((error as NSError).code) \(error.localizedDescription)")
            return false
        }
        AdLog.log("rewarded load OK — presenting")

        return await withCheckedContinuation { continuation in
            var didResume = false
            let delegate = RewardedAdDelegate { [weak self, continuation] rewarded in
                guard !didResume else { return }
                didResume = true
                self?.activeDelegate = nil
                continuation.resume(returning: rewarded)
            }
            activeDelegate = delegate
            ad.fullScreenContentDelegate = delegate
            ad.present(from: rootViewController) {
                delegate.rewardEarned = true
            }
        }
    }
}

/// `GADFullScreenContentDelegate` (Swift: `FullScreenContentDelegate`)
/// conformance needs a class, and the reward itself is only known for
/// certain once the ad actually finishes and dismisses — this bridges both
/// callbacks into the single `onFinish(Bool)` the `async` wrapper above
/// awaits.
private final class RewardedAdDelegate: NSObject, FullScreenContentDelegate {
    var rewardEarned = false
    private let onFinish: (Bool) -> Void

    init(onFinish: @escaping (Bool) -> Void) {
        self.onFinish = onFinish
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onFinish(rewardEarned)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onFinish(false)
    }
}
