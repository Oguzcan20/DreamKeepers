import SwiftUI

struct MissionsSheet: View {
    var gameState: GameState

    private var dailyMissions: [GameState.MissionStatus] {
        gameState.dailyMissions.filter { !$0.definition.isPremiumOnly }
    }

    private var bonusMissions: [GameState.MissionStatus] {
        gameState.dailyMissions.filter { $0.definition.isPremiumOnly }
    }

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 5).padding(.top, 8)

            Text("Missions")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Daily resets every day · Weekly resets every Monday")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Daily Missions", icon: "sun.max.fill")
                        missionGrid(dailyMissions)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Battle Pass Bonus", icon: "rosette")
                        missionGrid(bonusMissions)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader("Weekly Challenge", icon: "calendar")
                        if gameState.battlePassPremiumUnlocked {
                            weeklyMissionGrid
                        } else {
                            weeklyLockedCard
                        }
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .background(Theme.background.ignoresSafeArea())
    }

    private func sectionHeader(_ title: LocalizedStringKey, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.85))
    }

    private func missionGrid(_ missions: [GameState.MissionStatus]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 12) {
            ForEach(missions) { status in
                MissionRow(status: status) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if gameState.claimMission(status.id) {
                            gameState.playHaptic(.levelUp)
                        }
                    }
                }
            }
        }
    }

    private var weeklyMissionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 12) {
            ForEach(gameState.weeklyMissions) { status in
                WeeklyMissionRow(status: status) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if gameState.claimWeeklyMission(status.id) {
                            gameState.playHaptic(.levelUp)
                        }
                    }
                }
            }
        }
    }

    private var weeklyLockedCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.gold.opacity(0.7))
                Text("Unlock Battle Pass Premium to access harder weekly challenges with bigger rewards.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
    }
}

private struct MissionRow: View {
    let status: GameState.MissionStatus
    var onClaim: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: status.isLocked ? "lock.fill" : status.definition.icon)
                    .font(.title3)
                    .foregroundStyle(status.isLocked ? .white.opacity(0.3) : (status.isComplete ? Theme.gold : .white.opacity(0.4)))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(status.definition.title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(status.isLocked ? .white.opacity(0.4) : .white)
                    if status.isLocked {
                        Text("Requires Premium")
                            .font(.caption2)
                            .foregroundStyle(Theme.gold.opacity(0.7))
                    } else {
                        Text("\(status.progress)/\(status.definition.target)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    HStack(spacing: 8) {
                        if status.definition.goldReward > 0 {
                            Label("\(status.definition.goldReward)", systemImage: "circle.hexagongrid.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                        }
                        if status.definition.gemReward > 0 {
                            Label("\(status.definition.gemReward)", systemImage: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(Theme.violet)
                        }
                    }
                }

                Spacer()

                trailing
            }
        }
        .opacity(status.isLocked ? 0.6 : 1)
    }

    @ViewBuilder
    private var trailing: some View {
        if status.isLocked {
            EmptyView()
        } else if status.isClaimed {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Theme.gold)
                .accessibilityLabel("Claimed")
        } else if status.isComplete {
            Button("Claim", action: onClaim)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.gold.opacity(0.35))
                .clipShape(Capsule())
        } else {
            ProgressView(value: Double(status.progress), total: Double(status.definition.target))
                .tint(Theme.softBlue)
                .frame(width: 56)
        }
    }
}

private struct WeeklyMissionRow: View {
    let status: GameState.WeeklyMissionStatus
    var onClaim: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                Image(systemName: status.definition.icon)
                    .font(.title3)
                    .foregroundStyle(status.isComplete ? Theme.gold : .white.opacity(0.4))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(status.definition.title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(status.progress)/\(status.definition.target)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.55))
                    HStack(spacing: 8) {
                        if status.definition.goldReward > 0 {
                            Label("\(status.definition.goldReward)", systemImage: "circle.hexagongrid.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                        }
                        if status.definition.gemReward > 0 {
                            Label("\(status.definition.gemReward)", systemImage: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(Theme.violet)
                        }
                    }
                }

                Spacer()

                if status.isClaimed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.gold)
                        .accessibilityLabel("Claimed")
                } else if status.isComplete {
                    Button("Claim", action: onClaim)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Theme.gold.opacity(0.35))
                        .clipShape(Capsule())
                } else {
                    ProgressView(value: Double(status.progress), total: Double(status.definition.target))
                        .tint(Theme.softBlue)
                        .frame(width: 56)
                }
            }
        }
    }
}
