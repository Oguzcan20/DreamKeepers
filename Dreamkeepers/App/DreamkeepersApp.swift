import SwiftUI
import GoogleMobileAds

@main
struct DreamkeepersApp: App {
    init() {
        // `AdMobRewardService`'s ad unit is real, live inventory (see its
        // doc comment) — list real devices here to mark them as AdMob test
        // devices so repeated hands-on testing never counts as real ad
        // traffic. Find a device's identifier in its console log the first
        // time it requests that ad unit unregistered — the SDK prints a
        // line like `To get test ads on this device, set:
        // MobileAds.shared.requestConfiguration.testDeviceIdentifiers =
        // @[ @"XXXXXXXX-XXXX-..." ]`. Empty for now; add identifiers as
        // they turn up rather than leaving this commented out indefinitely.
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = []

        // Fire-and-forget: starts loading mediation adapters in the
        // background. `AdMobRewardService.showRewardedAd` degrades to "no
        // fill" (treated as a declined ad) rather than crashing if a load
        // is attempted before this finishes.
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
