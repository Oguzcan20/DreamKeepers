import Foundation
import GoogleMobileAds
import UserMessagingPlatform

/// Lightweight logging for the ad stack. Every failure in `AdMobRewardService`
/// / `AdMobInterstitialAdService` / `ConsentManager` was previously swallowed
/// silently (a failed load looks identical to a declined ad to the rest of
/// the app), which made "no ads show up on device" impossible to diagnose
/// without a debugger attached. These lines go to the unified log (visible in
/// Console.app and `xcrun devicectl device process launch --console`) under
/// the `[Ads]` prefix.
///
/// Purely diagnostic — no behaviour depends on it. Safe to keep in release
/// builds; `NSLog` volume here is a handful of lines per session.
enum AdLog {
    static func log(_ message: String) {
        NSLog("[Ads] %@", message)
    }

    /// One-shot dump of the SDK's current gating state — the two things that
    /// decide whether *any* ad can load: UMP consent (`canRequestAds`) and
    /// whether `MobileAds.start` has finished initialising adapters.
    @MainActor
    static func logRequestReadiness(context: String) {
        let consent = ConsentInformation.shared
        log("""
        readiness (\(context)): canRequestAds=\(consent.canRequestAds) \
        consentStatus=\(consentStatusName(consent.consentStatus)) \
        formStatus=\(formStatusName(consent.formStatus))
        """)
    }

    static func consentStatusName(_ status: ConsentStatus) -> String {
        switch status {
        case .unknown: return "unknown"
        case .required: return "required"
        case .notRequired: return "notRequired"
        case .obtained: return "obtained"
        @unknown default: return "unhandled(\(status.rawValue))"
        }
    }

    static func formStatusName(_ status: FormStatus) -> String {
        switch status {
        case .unknown: return "unknown"
        case .available: return "available"
        case .unavailable: return "unavailable"
        @unknown default: return "unhandled(\(status.rawValue))"
        }
    }
}
