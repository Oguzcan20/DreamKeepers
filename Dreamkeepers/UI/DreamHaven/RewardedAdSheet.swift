import SwiftUI

/// Rewarded-ad wrapper — see `AdRewardService`. The "playing" phase below is
/// only the loading/transition state; `AdMobRewardService` presents the
/// actual ad video full-screen on top of this sheet, and this view resumes
/// once that's dismissed, landing on rewarded/declined.
struct RewardedAdSheet: View {
    var gameState: GameState

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .playing

    private enum Phase { case playing, rewarded, declined }

    var body: some View {
        VStack(spacing: 20) {
            switch phase {
            case .playing:
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text("Loading Ad…")
                    .font(.headline)
                    .foregroundStyle(.white)
            case .rewarded:
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.25)).frame(width: 64, height: 64)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .shadow(color: Theme.gold.opacity(0.5), radius: 14)
                Text("Reward Claimed!")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                HStack(spacing: 16) {
                    Label("+\(GameState.rewardedAdGold)", systemImage: "circle.hexagongrid.fill")
                        .foregroundStyle(Theme.gold)
                    Label("+\(GameState.rewardedAdGems)", systemImage: "sparkles")
                        .foregroundStyle(Theme.violet)
                }
                .font(.headline)
                Button("Nice!") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    .padding(.horizontal, 40)
            case .declined:
                Text("Ad Unavailable")
                    .font(.headline)
                    .foregroundStyle(.white)
                Button("Close") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle(tint: Color.white.opacity(0.15)))
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .task {
            guard phase == .playing else { return }
            let rewarded = await gameState.watchRewardedAd()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                phase = rewarded ? .rewarded : .declined
            }
        }
    }
}
