import SwiftUI

/// Browsable list of every `AchievementSystem` milestone, locked or not —
/// the toast in `RootView` only ever shows a freshly-unlocked one in
/// passing, so this is the one place a player can see the full set and
/// what's left to chase. Presented as a sheet from `ProfileView`, same
/// pattern as `MissionsSheet`.
struct AchievementsSheet: View {
    var gameState: GameState

    private var unlockedCount: Int {
        gameState.save.unlockedAchievementIDs.count
    }

    var body: some View {
        VStack(spacing: 12) {
            Capsule().fill(.white.opacity(0.2)).frame(width: 36, height: 5).padding(.top, 8)

            Text("Achievements")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("\(unlockedCount)/\(AchievementSystem.all.count) unlocked")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), alignment: .top), GridItem(.flexible(), alignment: .top)], spacing: 12) {
                    ForEach(AchievementSystem.all) { achievement in
                        AchievementCard(
                            achievement: achievement,
                            isUnlocked: gameState.save.unlockedAchievementIDs.contains(achievement.id)
                        )
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .padding(.horizontal, 20)
        .background(Theme.background.ignoresSafeArea())
    }
}

private struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill((isUnlocked ? Theme.gold : .white).opacity(isUnlocked ? 0.22 : 0.06))
                        .frame(width: 40, height: 40)
                    Image(systemName: isUnlocked ? achievement.icon : "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(isUnlocked ? Theme.gold : .white.opacity(0.3))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(LocalizedStringKey(achievement.title))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isUnlocked ? .white : .white.opacity(0.45))
                    Text(LocalizedStringKey(achievement.detail))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(isUnlocked ? 0.6 : 0.35))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(Theme.gold)
                        .accessibilityLabel("Unlocked")
                }
            }
        }
        .opacity(isUnlocked ? 1 : 0.75)
    }
}
