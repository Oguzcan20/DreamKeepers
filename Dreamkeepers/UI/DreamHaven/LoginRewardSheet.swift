import SwiftUI

/// The daily login-streak calendar: 7 escalating rewards, one claim per
/// calendar day, streak resets to Day 1 if a day is skipped. Reachable two
/// ways — auto-presented once per launch from `RootView` the moment it's
/// available, and any time after via the gift button in `DreamHavenView`'s
/// header, so dismissing the auto-popup without claiming never loses it.
struct LoginRewardSheet: View {
    var gameState: GameState

    @Environment(\.dismiss) private var dismiss

    private var nextDay: Int { gameState.nextLoginRewardDay }
    private var isAvailable: Bool { gameState.isLoginRewardAvailable }

    /// Typed as `LocalizedStringKey` (not built as a `String` and wrapped
    /// after the fact) so the compiler resolves each interpolated branch
    /// against the catalog's `%lld`-keyed entries — a `LocalizedStringKey(_:)`
    /// call wrapped around an already-built ternary does not do this; the
    /// numbers just get baked into plain text no key will ever match.
    private var dayCaption: LocalizedStringKey {
        isAvailable ? "Day \(nextDay) of \(LoginRewardSystem.cycleLength)" : "Claimed — Day \(nextDay) tomorrow"
    }

    var body: some View {
        // A plain fixed `VStack` here squeezed or clipped the Claim button
        // off a short landscape `.medium`-detent sheet — reachable only by
        // dragging the sheet taller, which reads as broken on a "collect
        // your reward" screen. Keeping the header and the Claim button fixed
        // and letting only the 7-day grid scroll (it rarely needs to) keeps
        // Claim on-screen and tappable the instant the sheet opens.
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.25)).frame(width: 64, height: 64)
                    Image(systemName: "gift.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                .shadow(color: Theme.gold.opacity(0.5), radius: 14)
                .padding(.top, 22)
                .padding(.bottom, 6)

                Text("Daily Login Bonus")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(dayCaption)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.bottom, 18)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 12) {
                    ForEach(LoginRewardSystem.days) { reward in
                        LoginRewardDayCell(reward: reward, state: cellState(for: reward.day))
                    }
                }
                .padding(.horizontal, 20)
            }

            Button {
                gameState.claimLoginReward()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss() }
            } label: {
                Text(LocalizedStringKey(isAvailable ? "Claim" : "See You Tomorrow"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle(tint: isAvailable ? Theme.gold : Color.white.opacity(0.15)))
            .disabled(!isAvailable)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private func cellState(for day: Int) -> LoginRewardDayState {
        if isAvailable {
            if day < nextDay { return .claimed }
            if day == nextDay { return .current }
            return .locked
        }
        // Already claimed today — today's own slot still reads as claimed.
        return day <= gameState.save.loginStreakDay ? .claimed : .locked
    }
}

enum LoginRewardDayState {
    case claimed, current, locked
}

private struct LoginRewardDayCell: View {
    var reward: LoginRewardDay
    var state: LoginRewardDayState

    // See `LoginRewardSheet.dayCaption` — same reasoning applies here.
    private var rewardCaption: LocalizedStringKey {
        reward.gems > 0 ? "\(reward.gems) Gems" : "\(reward.gold) Gold"
    }

    var body: some View {
        VStack(spacing: 6) {
            Text("Day \(reward.day)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            ZStack {
                Circle()
                    .fill(state == .current ? Theme.gold.opacity(0.25) : Color.white.opacity(0.06))
                    .overlay(
                        Circle().stroke(state == .current ? Theme.gold : Color.white.opacity(0.12), lineWidth: state == .current ? 2 : 1)
                    )
                Image(systemName: state == .claimed ? "checkmark" : reward.icon)
                    .foregroundStyle(state == .locked ? .white.opacity(0.3) : (state == .claimed ? Theme.gold : .white))
            }
            .frame(width: 46, height: 46)
            Text(rewardCaption)
                .font(.caption2)
                .foregroundStyle(.white.opacity(state == .locked ? 0.3 : 0.7))
        }
        .opacity(state == .locked ? 0.55 : 1)
    }
}
