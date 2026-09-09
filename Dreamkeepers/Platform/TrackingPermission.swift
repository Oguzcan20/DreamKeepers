import AppTrackingTransparency
import Foundation

/// App Tracking Transparency (ATT) — the iOS 14+ permission prompt that gates
/// access to the IDFA. Google Mobile Ads still serves ads without it, but
/// fill rate and CPM for a fresh ad unit/account are meaningfully worse
/// without it, since AdMob can't personalize or attribute as well. `NSUserTrackingUsageDescription`
/// (in `project.yml`) supplies the prompt's explanation text.
///
/// Calling `requestTrackingAuthorization` when the status is already
/// determined (a prior grant/deny, or "restricted" via parental controls)
/// just returns that status immediately without prompting again — safe to
/// call once per launch without tracking "did we already ask" ourselves.
enum TrackingPermission {
    /// Requests ATT if the user hasn't been asked yet. Call this once the
    /// app is fully active and visible — Apple's prompt silently no-ops if
    /// fired while the app is still transitioning into the foreground (e.g.
    /// immediately at cold launch), so `RootView` waits a beat after its
    /// first appearance before calling this.
    @MainActor
    static func requestIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
}
