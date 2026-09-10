import Foundation
import GoogleMobileAds
import UIKit

/// One seam for automatic (non-rewarded) interstitial ads — same shape as
/// `AdRewardService`, kept as a separate protocol because it's a distinct
/// concern (paced automatically by `GameState`, not player-initiated, and
/// never grants a currency reward).
///
///     InterstitialAdService
///      ├── MockInterstitialAdService   (used in tests)
///      └── AdMobInterstitialAdService  (active)
protocol InterstitialAdService {
    /// Loads and presents an interstitial, returning once it's been
    /// dismissed (or failed to load/present — the caller doesn't need to
    /// distinguish those, unlike a rewarded ad there's no reward to
    /// withhold either way).
    @MainActor
    func showInterstitialAd() async
}

/// Test/development placeholder: simulates the brief load a real
/// interstitial takes, shows nothing.
struct MockInterstitialAdService: InterstitialAdService {
    @MainActor
    func showInterstitialAd() async {
        try? await Task.sleep(nanoseconds: 1_500_000_000)
    }
}

/// Real interstitial ads via the Google Mobile Ads SDK. `adUnitID` is the
/// real "Interstitial_AutoAd" unit created in the AdMob console for
/// "DreamKeepers" on 2026-09-05 (App ID ca-app-pub-6011422497566268~3187851752,
/// same app as the rewarded unit) — see `AdMobRewardService`'s doc comment
/// for the same real-ad-unit safety note (don't script/automate triggering
/// this against a real unit — it's billable, non-test inventory now).
final class AdMobInterstitialAdService: InterstitialAdService {
    /// Real "Interstitial_AutoAd" unit (AdMob console, 2026-09-05). Same
    /// story as `AdMobRewardService.realAdUnitID` — a new unit on a new app
    /// won't fill before the app is live on the App Store. Swap `adUnitID`
    /// to this at launch.
    static let realAdUnitID = "ca-app-pub-6011422497566268/4756154109"

    /// Google's published iOS interstitial **test unit** — always fills,
    /// never billable. Matches the Android (Flutter) port, so interstitials
    /// actually appear on device during development.
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"

    /// Same reasoning as `AdMobRewardService.activeDelegate`:
    /// `fullScreenContentDelegate` is `weak`, so this is the only thing
    /// keeping the delegate alive between "present" and "dismissed".
    private var activeDelegate: InterstitialAdDelegate?

    @MainActor
    func showInterstitialAd() async {
        guard let rootViewController = UIApplication.dk_rootViewController else { return }

        AdLog.logRequestReadiness(context: "interstitial load")

        let ad: InterstitialAd
        do {
            ad = try await InterstitialAd.load(with: adUnitID, request: Request())
        } catch {
            AdLog.log("interstitial load FAILED: \((error as NSError).domain)#\((error as NSError).code) \(error.localizedDescription)")
            return
        }
        AdLog.log("interstitial load OK — presenting")

        await withCheckedContinuation { continuation in
            var didResume = false
            let delegate = InterstitialAdDelegate { [weak self] in
                guard !didResume else { return }
                didResume = true
                self?.activeDelegate = nil
                continuation.resume()
            }
            activeDelegate = delegate
            ad.fullScreenContentDelegate = delegate
            ad.present(from: rootViewController)
        }
    }
}

private final class InterstitialAdDelegate: NSObject, FullScreenContentDelegate {
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        onFinish()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        onFinish()
    }
}
