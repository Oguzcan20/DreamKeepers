import Foundation
import UIKit
import UserMessagingPlatform

/// Google's EU User Consent Policy requires an in-app Consent Management
/// Platform (CMP) flow before requesting or serving personalized ads to
/// users in the EEA, UK, and Switzerland. Dreamkeepers' player base is
/// German/EU-facing, so this isn't optional. Wraps Google's own User
/// Messaging Platform (UMP) SDK — bundled as a dependency of GoogleMobileAds
/// but never previously wired up (see COMPLIANCE_CHECKLIST.md, finding #3).
///
/// Must run and complete *before* `TrackingPermission.requestIfNeeded()` and
/// before any ad request, per Google's own integration guide — `RootView`
/// calls `ConsentManager.requestConsentIfNeeded()` first, then ATT.
enum ConsentManager {
    /// Requests a consent-info update from Google and presents the consent
    /// form only if the SDK determines one is actually required for this
    /// user (EEA/UK/Switzerland and not already recorded). No-ops for every
    /// other region, where `loadAndPresentIfRequired` returns immediately
    /// without showing anything.
    @MainActor
    static func requestConsentIfNeeded() async {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { _ in
                continuation.resume()
            }
        }

        guard let rootViewController = UIApplication.dk_rootViewController else { return }

        await withCheckedContinuation { continuation in
            ConsentForm.loadAndPresentIfRequired(from: rootViewController) { _ in
                continuation.resume()
            }
        }
    }
}
