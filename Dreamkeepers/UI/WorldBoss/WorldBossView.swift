import SwiftUI

/// World Boss hub ("Voidmaw, the Devouring Dream") — status/countdown,
/// remaining attacks, the Attack button, and the live weekly leaderboard.
/// Mirrors `DungeonView`'s hub shape (header, status card, scrollable list)
/// at boss-fight scale: one shared card instead of a list of dungeons.
struct WorldBossView: View {
    var gameState: GameState
    var leaderboardService: WorldBossLeaderboardService
    var navigate: (AppRoute) -> Void
    var onFight: () -> Void

    @State private var appeared = false
    @State private var showNoTeamAlert = false
    @State private var showRewards = false

    private var hasBossArt: Bool { MonsterArt.hasArt(for: WorldBossSystem.bossName) }
    /// Refreshed every second via the `TimelineView` below so the countdown
    /// actually counts down instead of freezing at the value read on appear.
    @State private var now = Date()

    private var weekID: String { WorldBossSystem.weekID(for: now) }
    private var window: (start: Date, end: Date) { WorldBossSystem.window(for: now) }
    private var isActive: Bool { WorldBossSystem.isActive(at: now) }

    var body: some View {
        ZStack {
            AmbientBackground(topTint: .red, bottomTint: Theme.violet)

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                ScrollView {
                    VStack(spacing: 12) {
                        statusCard
                        if gameState.hasUnclaimedWorldBossReward {
                            claimCard
                        }
                        leaderboardCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            leaderboardService.listen(weekID: weekID)
        }
        .alert("No team deployed", isPresented: $showNoTeamAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deploy a team before attacking the World Boss.")
        }
    }

    private var header: some View {
        HStack {
            Button {
                navigate(.dreamHaven)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Back")
            Spacer()
            Text("World Boss")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                showRewards = true
            } label: {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Rewards")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .sheet(isPresented: $showRewards) {
            WorldBossRewardsSheet()
                .presentationDetents([.medium, .large])
        }
    }

    private var statusCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    ZStack {
                        if hasBossArt {
                            Image(MonsterArt.assetName(for: WorldBossSystem.bossName))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 52, height: 52)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.red.opacity(0.7), lineWidth: 2))
                                .shadow(color: .red.opacity(0.6), radius: 12)
                        } else {
                            Circle().fill(Color.red.opacity(0.3)).frame(width: 52, height: 52)
                                .shadow(color: .red.opacity(0.6), radius: 12)
                            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voidmaw, the Devouring Dream")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Text(countdownText(at: context.date))
                                .font(.caption)
                                .foregroundStyle(isActive ? Theme.gold : .white.opacity(0.6))
                        }
                    }
                    Spacer()
                }

                Divider().background(Color.white.opacity(0.1))

                HStack {
                    statPill(title: "Attacks Left", value: "\(gameState.worldBossAttacksRemaining)/\(WorldBossSystem.attacksPerWeek)")
                    statPill(title: "Damage This Week", value: "\(gameState.worldBossDamageDealtThisWeek)")
                }

                Button {
                    attemptFight()
                } label: {
                    Text("Attack")
                }
                .buttonStyle(PrimaryButtonStyle(tint: .red))
                .disabled(!isActive || gameState.worldBossAttacksRemaining <= 0 || gameState.deployedTeam.isEmpty)
            }
        }
    }

    private func statPill(title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var claimCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.7), radius: 12)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last week's reward is ready")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    if let rank = leaderboardService.myRank {
                        Text("Rank #\(rank)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
                Spacer()
                Button {
                    _ = gameState.claimWorldBossReward(rank: leaderboardService.myRank ?? Int.max)
                } label: {
                    Text("Claim")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                .frame(width: 100)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.gold.opacity(0.3), radius: 14, y: 4)
    }

    private var leaderboardCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Leaderboard")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    if let rank = leaderboardService.myRank {
                        Text("Your Rank: #\(rank)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }
                }

                if !leaderboardService.isConfigured {
                    Text("Leaderboard unavailable.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                } else if leaderboardService.top.isEmpty {
                    Text("No attacks recorded yet this week. Be the first!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(leaderboardService.top.prefix(20).enumerated()), id: \.element.id) { index, entry in
                            leaderboardRow(rank: index + 1, entry: entry)
                        }
                    }
                }
            }
        }
    }

    private func leaderboardRow(rank: Int, entry: WorldBossLeaderboardService.Entry) -> some View {
        HStack {
            Text("#\(rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(rank <= 3 ? Theme.gold : .white.opacity(0.6))
                .frame(width: 32, alignment: .leading)
            Text("Lv \(entry.playerLevel)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text("\(entry.damage)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }

    private func attemptFight() {
        guard !gameState.deployedTeam.isEmpty else {
            showNoTeamAlert = true
            return
        }
        onFight()
    }

    private func countdownText(at date: Date) -> String {
        now = date
        let w = WorldBossSystem.window(for: date)
        if date < w.start {
            return "Appears in \(Self.format(w.start.timeIntervalSince(date)))"
        } else if date < w.end {
            return "Ends in \(Self.format(w.end.timeIntervalSince(date)))"
        } else {
            // `w.start` is the most recently *started* cycle (weekStart biases
            // backward through the whole dormant gap between last Sunday
            // 19:00 and next Friday 19:00 — see `WorldBossSystem.weekStart`),
            // so the next appearance is always exactly 7 days after it.
            // Re-deriving via `window(for: date + 1s)` looked equivalent but
            // resolves to that same already-closed window for the entire
            // dormant week, not just the instant before it flips — producing
            // a negative interval that `format` clamped to "00m 00s".
            let nextStart = w.start.addingTimeInterval(7 * 86_400)
            return "Next boss: \(Self.format(nextStart.timeIntervalSince(date)))"
        }
    }

    private static func format(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval))
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if days > 0 { return String(format: "%dd %02dh", days, hours) }
        if hours > 0 { return String(format: "%dh %02dm", hours, minutes) }
        return String(format: "%02dm %02ds", minutes, seconds)
    }
}

/// Shows the rank->reward table `WorldBossSystem.reward(forRank:)` already
/// computes but never surfaced anywhere — presented as a sheet from
/// `WorldBossView`'s header, same pattern as `AchievementsSheet`. Reads the
/// brackets straight from `WorldBossSystem` so this never drifts out of sync
/// with the real payout logic.
struct WorldBossRewardsSheet: View {
    private struct Bracket: Identifiable {
        var id: Int
        var rankLabel: LocalizedStringKey
        var reward: WorldBossSystem.Reward
    }

    /// Mirrors the exact rank bins `WorldBossSystem.reward(forRank:)`
    /// switches on — rank 2's reward stands in for the whole 2-10 bracket
    /// since it pays the most within it (a linear step-down per rank).
    private var brackets: [Bracket] {
        [1, 2, 11, 51, 101].compactMap { rank in
            guard let reward = WorldBossSystem.reward(forRank: rank) else { return nil }
            let label: LocalizedStringKey
            switch rank {
            case 1: label = "Rank 1"
            case 2: label = "Rank 2-10"
            case 11: label = "Rank 11-50"
            case 51: label = "Rank 51-100"
            default: label = "Rank 101-200"
            }
            return Bracket(id: rank, rankLabel: label, reward: reward)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 5).padding(.top, 8)

            Text("Rewards")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Paid out at the end of each week, by leaderboard rank")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(brackets) { bracket in
                        rewardRow(bracket)
                    }
                    Text("No reward past rank 200")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 4)
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .background(Theme.background.ignoresSafeArea())
    }

    private func rewardRow(_ bracket: Bracket) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                Text(bracket.rankLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                    Text("\(bracket.reward.gold)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                }
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.violet)
                    Text("\(bracket.reward.gems)")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
