import SwiftUI

/// Season Pass (spec screen #13: "Battle Pass — Kostenlose und Premium-Spur").
/// Every battle win grants season XP; each tier unlocks a free reward and,
/// once Premium is purchased, a richer premium reward on the same tier.
struct BattlePassView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var justClaimedID: String?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    xpCard

                    if !gameState.battlePassPremiumUnlocked {
                        premiumUpsellCard
                    }

                    LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 10) {
                        ForEach(1...BattlePassSystem.tierCount, id: \.self) { tier in
                            TierRow(
                                tier: tier,
                                isUnlocked: tier <= gameState.battlePassTier,
                                premiumUnlocked: gameState.battlePassPremiumUnlocked,
                                freeState: rewardState(tier: tier, premium: false),
                                premiumState: rewardState(tier: tier, premium: true),
                                onClaimFree: { claim(tier: tier, premium: false) },
                                onClaimPremium: { claim(tier: tier, premium: true) }
                            )
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
    }

    private func rewardState(tier: Int, premium: Bool) -> TierRow.RewardState {
        if gameState.isBattlePassRewardClaimed(tier: tier, premium: premium) { return .claimed }
        if gameState.canClaimBattlePassReward(tier: tier, premium: premium) { return .claimable }
        return .locked
    }

    private func claim(tier: Int, premium: Bool) {
        guard gameState.claimBattlePassReward(tier: tier, premium: premium) else { return }
        gameState.playHaptic(.success)
        justClaimedID = "\(tier)-\(premium)"
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
            VStack(spacing: 2) {
                Text("Season Pass")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("Tier \(gameState.battlePassTier)/\(BattlePassSystem.tierCount)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                ResourcePill(systemImage: "circle.hexagongrid.fill", value: "\(gameState.save.gold)", tint: Theme.gold, accessibilityLabelText: "Gold")
                ResourcePill(systemImage: "sparkles", value: "\(gameState.save.dreamGems)", tint: Theme.violet, accessibilityLabelText: "Dream Gems")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    /// Makes the underlying points system legible: how much Season XP the
    /// player has right now, how much the next tier needs, and how to earn
    /// more — the tier number alone (in the header) wasn't explaining that.
    private var xpCard: some View {
        let progress = gameState.battlePassProgress
        let atMaxTier = gameState.battlePassTier >= BattlePassSystem.tierCount
        return GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Season XP")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(atMaxTier ? "Max Tier Reached" : "\(progress.current)/\(progress.needed) XP")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule().fill(Theme.gold)
                            .frame(width: max(6, geo.size.width * CGFloat(progress.current) / CGFloat(progress.needed)))
                    }
                }
                .frame(height: 8)

                Text("Win battles to earn Season XP — bosses grant more. Each tier unlocks a Free reward automatically; tap the arrow on a tier to claim it, or claim the matching Premium reward too once unlocked.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var premiumUpsellCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "rosette")
                    .font(.system(size: 34))
                    .foregroundStyle(Theme.gold)
                Text("Unlock Premium Track")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Claim the gold and gem rewards on every tier you've already reached — no rush, they stay unlocked for the rest of the season.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Button("$4.99") {
                    guard gameState.purchaseBattlePassPremium() else { return }
                    gameState.playHaptic(.levelUp)
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
    }
}

private struct TierRow: View {
    enum RewardState { case locked, claimable, claimed }

    let tier: Int
    let isUnlocked: Bool
    let premiumUnlocked: Bool
    let freeState: RewardState
    let premiumState: RewardState
    var onClaimFree: () -> Void
    var onClaimPremium: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? Theme.softBlue.opacity(0.35) : Color.white.opacity(0.06))
                        .frame(width: 36, height: 36)
                    Text("\(tier)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isUnlocked ? .white : .white.opacity(0.4))
                }

                RewardSlot(
                    reward: BattlePassSystem.freeReward(forTier: tier), tint: Theme.softBlue,
                    state: freeState, isLockedByPremium: false, onClaim: onClaimFree
                )
                RewardSlot(
                    reward: BattlePassSystem.premiumReward(forTier: tier), tint: Theme.gold,
                    state: premiumState, isLockedByPremium: isUnlocked && !premiumUnlocked, onClaim: onClaimPremium
                )
            }
        }
        .opacity(isUnlocked ? 1 : 0.55)
    }
}

private struct RewardSlot: View {
    let reward: BattlePassSystem.Reward
    let tint: Color
    let state: TierRow.RewardState
    let isLockedByPremium: Bool
    var onClaim: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Label("\(reward.gold)", systemImage: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                if reward.gems > 0 {
                    Label("\(reward.gems)", systemImage: "sparkles")
                        .foregroundStyle(Theme.violet)
                }
                if reward.tickets > 0 {
                    Label("\(reward.tickets)", systemImage: "ticket.fill")
                        .foregroundStyle(Theme.softBlue)
                }
            }
            .font(.caption2.weight(.semibold))

            Spacer(minLength: 4)

            switch state {
            case .claimed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green.opacity(0.8))
            case .claimable:
                Button(action: onClaim) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(tint)
                }
            case .locked:
                // Tinted gold when the tier is already reached and the only
                // thing missing is Premium — a visual nudge toward the upsell.
                Image(systemName: "lock.fill")
                    .foregroundStyle(isLockedByPremium ? Theme.gold.opacity(0.6) : .white.opacity(0.3))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
