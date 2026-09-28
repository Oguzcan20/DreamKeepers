import SwiftUI

struct ProfileView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var showAchievements = false

    private var expToNext: Int {
        LevelSystem.expToNextLevel(from: gameState.save.playerLevel)
    }

    private var isMaxLevel: Bool {
        gameState.save.playerLevel >= LevelSystem.maxLevel
    }

    private var stagesCleared: Int {
        min(gameState.save.currentStage - 1, WorldCatalog.totalStages)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(alignment: .top, spacing: 16) {
                levelCard
                    .frame(maxWidth: .infinity)
                statsGrid
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
            .frame(maxHeight: .infinity)
            // Fixed layout, no `ScrollView` — scale to fill whatever space
            // is there instead of clipping/sitting small. Reference is
            // deliberately smaller than DreamHavenView's (874×402, scaled
            // 0.8x here) so this two-card screen visibly grows on big
            // phones (Pro Max etc.) too, not just barely — a plain 1.0-cap
            // scale landed near 1.0x there since Pro Max's landscape size
            // is close to the 17 Pro reference size to begin with.
            .adaptiveScale(reference: CGSize(width: 600, height: 220), maxScale: 1.4)
        }
        .background(Theme.background.ignoresSafeArea())
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
            Text("Profile")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                navigate(.friends)
            } label: {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Friends")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var levelCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.gold.opacity(0.25))
                        .frame(width: 72, height: 72)
                        .shadow(color: Theme.gold.opacity(0.5), radius: 12)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }

                if let playerName = gameState.playerName {
                    Text(playerName)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Player Level \(gameState.save.playerLevel)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Player Level \(gameState.save.playerLevel)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                if isMaxLevel {
                    Text("Max level reached")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    VStack(spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12))
                                Capsule().fill(Theme.gold)
                                    .frame(width: geo.size.width * min(1, Double(gameState.save.playerExp) / Double(expToNext)))
                            }
                        }
                        .frame(height: 10)
                        .frame(maxWidth: .infinity)

                        Text("\(gameState.save.playerExp) / \(expToNext) EXP to next level")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsGrid: some View {
        GlassCard {
            VStack(spacing: 14) {
                Text("Journey So Far")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    ProfileStatColumn(icon: "sparkles", label: "Dreamkeepers", value: "\(gameState.ownedSpeciesCount)/\(gameState.catalog.definitions.count)")
                    ProfileStatColumn(icon: "map.fill", label: "Stages Cleared", value: "\(stagesCleared)/\(WorldCatalog.totalStages)")
                    ProfileStatColumn(icon: "circle.hexagongrid.fill", label: "Gold", value: "\(gameState.save.gold)")
                    ProfileStatColumn(icon: "star.fill", label: "Dream Gems", value: "\(gameState.save.dreamGems)")
                }

                Button { showAchievements = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rosette")
                            .foregroundStyle(Theme.gold)
                        Text("Achievements")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(gameState.save.unlockedAchievementIDs.count)/\(AchievementSystem.all.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.55))
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsSheet(gameState: gameState)
                .presentationDetents([.large])
        }
    }
}

private struct ProfileStatColumn: View {
    var icon: String
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(Theme.softBlue)
                .font(.subheadline)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
            Text(LocalizedStringKey(label))
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                // Without this, squeezing the column narrower (which
                // `AdaptiveScale`'s smaller reference width does on purpose,
                // to grow more on big screens) truncates to "Dreamk…"
                // instead of wrapping to a second line.
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }
}
