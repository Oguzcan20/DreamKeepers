import SwiftUI

struct GoldFountainSheet: View {
    var gameState: GameState

    @Environment(\.dismiss) private var dismiss
    @State private var justCollected: Int?

    var body: some View {
        VStack(spacing: 14) {
            header
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                fountainCard
            }
            collectButton
        }
        .padding(20)
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            if let justCollected {
                CollectConfirmation(text: "+\(justCollected) Gold", tint: Theme.gold)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Gold Fountain")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Generates \(OfflineRewards.goldPerMinute) gold/min while you're away · caps after 8h")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var fountainCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .opacity(0.5)
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("+\(gameState.pendingGoldFountainReward)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gold)
                    Group {
                        if justCollected != nil {
                            Text("Collected!")
                        } else {
                            Text("Gold ready to collect")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var collectButton: some View {
        Button {
            let amount = gameState.collectGoldFountain()
            guard amount > 0 else { return }
            gameState.playHaptic(.levelUp)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { justCollected = amount }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
        } label: {
            Label("Collect", systemImage: "hand.tap.fill")
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
        .disabled(gameState.pendingGoldFountainReward <= 0 || justCollected != nil)
    }
}
