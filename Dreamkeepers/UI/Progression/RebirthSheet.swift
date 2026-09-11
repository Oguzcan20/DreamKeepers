import SwiftUI

/// Rebirth ("Wiedergeburt") sheet — resets `arenaFloor` back to 1 in exchange
/// for permanent Soul Points spent on four percentage-based account buffs.
/// Presented from `ArenaView` since floor progress is the rebirth gate.
struct RebirthSheet: View {
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    balanceCard
                    rebirthActionCard
                    ForEach(SoulUpgrade.allCases) { upgrade in
                        UpgradeRow(upgrade: upgrade, gameState: gameState)
                    }
                }
                .padding(20)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Rebirth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Rebirth?", isPresented: $showConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Rebirth", role: .destructive) {
                gameState.performRebirth()
                gameState.playHaptic(.success)
            }
        } message: {
            Text("Your Endless Trial floor resets to 1 in exchange for \(gameState.pendingRebirthSoulPoints) Soul Points. Your roster, gear, and gold are untouched.")
        }
    }

    private var balanceCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.violet.opacity(0.3)).frame(width: 48, height: 48)
                    Image(systemName: "sparkle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.violet)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(gameState.soulPoints) Soul Points")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Rebirths: \(gameState.rebirthCount)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private var rebirthActionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Reach floor \(RebirthSystem.rebirthFloorRequirement) of the Endless Trial to rebirth.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                HStack {
                    Text(gameState.canRebirth ? "+\(gameState.pendingRebirthSoulPoints) Soul Points" : "Floor \(min(gameState.arenaFloor, gameState.arenaMaxFloor))/\(RebirthSystem.rebirthFloorRequirement)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(gameState.canRebirth ? Theme.gold : .white.opacity(0.5))
                    Spacer()
                    Button("Rebirth") { showConfirm = true }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                        .disabled(!gameState.canRebirth)
                        .opacity(gameState.canRebirth ? 1 : 0.35)
                }
            }
        }
    }
}

private struct UpgradeRow: View {
    let upgrade: SoulUpgrade
    var gameState: GameState

    private var rank: Int { gameState.soulUpgradeRank(upgrade) }
    private var maxRank: Int { RebirthSystem.maxRank(upgrade) }
    private var isMaxed: Bool { rank >= maxRank }
    private var cost: Int { RebirthSystem.costForRank(upgrade, rank + 1) }
    private var canAfford: Bool { gameState.soulPoints >= cost }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.25)).frame(width: 44, height: 44)
                    Image(systemName: upgrade.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(upgrade.displayName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(upgrade.detail)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Rank \(rank)/\(maxRank)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.softBlue)
                }
                Spacer()
                if isMaxed {
                    Text("Max")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                } else {
                    Button("\(cost) SP") {
                        gameState.buySoulUpgrade(upgrade)
                        gameState.playHaptic(.light)
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    .disabled(!canAfford)
                    .opacity(canAfford ? 1 : 0.4)
                }
            }
        }
    }
}
