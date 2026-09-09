import SwiftUI

/// Full-screen automatic interstitial — see `GameState.shouldShowInterstitial`.
/// No reward, no user choice: it loads, presents (the ad SDK takes over the
/// screen itself), and this dismisses the instant that's done. `RootView`
/// presents it right after a battle-result screen is dismissed.
struct InterstitialAdSheet: View {
    var gameState: GameState

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.4)
            Text("Loading Ad…")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .task {
            await gameState.showInterstitialAd()
            dismiss()
        }
    }
}
