import SwiftUI

struct TrainingGardenSheet: View {
    var gameState: GameState

    @Environment(\.dismiss) private var dismiss
    @State private var lastResult: GameState.TrainingResult?
    @State private var showConfirmation = false

    var body: some View {
        VStack(spacing: 14) {
            header
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                gardenCard
            }
            if let result = lastResult, !result.levelUps.isEmpty {
                levelUpsCard(result.levelUps)
            }
            collectButton
        }
        .padding(20)
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            if showConfirmation, let result = lastResult {
                CollectConfirmation(text: "+\(result.expGranted) EXP", tint: Theme.softBlue)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Training Garden")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Grants \(OfflineRewards.expPerMinute) EXP/min to your deployed team while you're away · caps after 8h")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var gardenCard: some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.softBlue)
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .opacity(0.5)
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(.system(size: 32))
                        .foregroundStyle(Theme.softBlue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("+\(gameState.pendingTrainingGardenReward) EXP")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.softBlue)
                    Group {
                        if gameState.deployedTeam.isEmpty {
                            Text("Deploy a team to put the garden to work.")
                        } else {
                            Text("Ready for your deployed team")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func levelUpsCard(_ levelUps: [LevelUpSummary]) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Level Up!")
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(levelUps) { levelUp in
                    HStack {
                        Text(levelUp.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Lv \(levelUp.oldLevel) → Lv \(levelUp.newLevel)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
        }
        .transition(.opacity)
    }

    private var collectButton: some View {
        Button {
            let result = gameState.collectTrainingGarden()
            guard let result else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                lastResult = result
                showConfirmation = true
            }
            gameState.playHaptic(.levelUp)
            let delay = result.levelUps.isEmpty ? 0.9 : 1.6
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { dismiss() }
        } label: {
            Label("Collect", systemImage: "hand.tap.fill")
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.softBlue))
        .disabled(gameState.pendingTrainingGardenReward <= 0 || gameState.deployedTeam.isEmpty || showConfirmation)
    }
}
