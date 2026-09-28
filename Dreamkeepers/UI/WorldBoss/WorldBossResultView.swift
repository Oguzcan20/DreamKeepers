import SwiftUI

/// World Boss attempt result — damage-dealt framing rather than Victory/Defeat,
/// since a single attack on the boss is never really "won" or "lost."
/// Mirrors `ArenaResultView`'s result-screen shape.
struct WorldBossResultView: View {
    var summary: WorldBossBattleResultSummary
    var onFightAgain: () -> Void
    var onDreamHaven: () -> Void

    @State private var appeared = false

    private var headline: LocalizedStringKey {
        switch summary.outcome {
        case .victory: return "Boss Defeated!"
        case .timeout: return "Time's Up!"
        case .defeat: return "Team Down!"
        }
    }

    private var tint: Color {
        switch summary.outcome {
        case .victory: return Theme.gold
        case .timeout: return Theme.violet
        case .defeat: return .red
        }
    }

    private var subheadline: LocalizedStringKey {
        switch summary.outcome {
        case .victory: return "You brought the boss down before time ran out."
        case .timeout: return "The boss still stands, but every hit counted."
        case .defeat: return "Your team fell, but the damage is already banked."
        }
    }

    var body: some View {
        ZStack {
            AmbientBackground(topTint: tint, bottomTint: Theme.violet)

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    if MonsterArt.hasArt(for: WorldBossSystem.bossName) {
                        Image(MonsterArt.assetName(for: WorldBossSystem.bossName))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(tint.opacity(0.7), lineWidth: 2))
                            .shadow(color: tint.opacity(0.6), radius: 16)
                    } else {
                        Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(tint)
                            .shadow(color: tint.opacity(0.6), radius: 16)
                    }
                    Text(headline)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)
                    Text(subheadline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

                GlassCard {
                    VStack(spacing: 14) {
                        resultRow(title: "Damage This Attempt", value: "\(summary.damageDealtThisAttempt)")
                        Divider().background(Color.white.opacity(0.1))
                        resultRow(title: "Total Damage This Week", value: "\(summary.totalDamageThisWeek)")
                        Divider().background(Color.white.opacity(0.1))
                        resultRow(title: "Attacks Remaining", value: "\(summary.attacksRemaining)/\(WorldBossSystem.attacksPerWeek)")
                    }
                }
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    if summary.attacksRemaining > 0 {
                        Button {
                            onFightAgain()
                        } label: {
                            Text("Attack Again")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: .red))
                    }

                    Button {
                        onDreamHaven()
                    } label: {
                        Text("Dream Haven")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private func resultRow(title: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
}
