import SwiftUI

/// Dungeon hub ("Schlünde") — a short, fixed list of three multi-wave
/// dungeons (unlike the 100-floor Endless Trial), each capped at one key per
/// attempt and `DungeonSystem.maxKeysPerDay` keys/day. Mirrors `ArenaView`'s
/// visual language (AmbientBackground, GlassCard rows) at a smaller scale.
struct DungeonView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void
    var onFight: (DungeonID) -> Void

    @State private var appeared = false
    @State private var showNoKeysAlert = false
    @State private var showNoTeamAlert = false

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.violet, bottomTint: Theme.gold)

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                keysCard
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .opacity(appeared ? 1 : 0)

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(gameState.dungeons) { dungeon in
                            DungeonCard(dungeon: dungeon, gameState: gameState, onFight: attemptFight)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .alert("No Keys Left", isPresented: $showNoKeysAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've used all your dungeon keys for today. Come back tomorrow!")
        }
        .alert("No team deployed", isPresented: $showNoTeamAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deploy a team before entering a dungeon.")
        }
    }

    private func attemptFight(_ dungeon: DungeonID) {
        guard !gameState.deployedTeam.isEmpty else {
            showNoTeamAlert = true
            return
        }
        guard gameState.dungeonKeysRemainingToday > 0 else {
            showNoKeysAlert = true
            return
        }
        onFight(dungeon)
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
            Text("Dungeons")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var keysCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.violet.opacity(0.25)).frame(width: 48, height: 48)
                    Image(systemName: "key.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.violet)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dungeon Keys")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Refills daily")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Text("\(gameState.dungeonKeysRemainingToday)/\(gameState.maxDungeonKeysPerDay)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

/// One dungeon's row in the hub — icon, name, cleared badge, recommended
/// level, a short blurb, reward chips (first-clear preview if uncleared,
/// repeat gold otherwise), and an Enter/Farm button.
private struct DungeonCard: View {
    let dungeon: DungeonID
    var gameState: GameState
    var onFight: (DungeonID) -> Void

    private var isCleared: Bool { gameState.isDungeonCleared(dungeon) }
    private var canEnter: Bool { gameState.canEnterDungeon(dungeon) }
    private var rarity: Rarity { DungeonSystem.firstClearRarity(dungeon) }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.violet.opacity(0.3)).frame(width: 46, height: 46)
                    Image(systemName: DungeonSystem.icon(dungeon))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(DungeonSystem.displayName(dungeon))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        if isCleared {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green.opacity(0.75))
                        }
                    }
                    Text("Recommended Lv \(DungeonSystem.recommendedLevel(dungeon))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(DungeonSystem.blurb(dungeon))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(2)
                    rewardPreview
                }

                Spacer()

                Button {
                    onFight(dungeon)
                } label: {
                    Text(isCleared ? "Farm" : "Enter")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                .disabled(!canEnter)
                .opacity(canEnter ? 1 : 0.35)
            }
        }
    }

    @ViewBuilder
    private var rewardPreview: some View {
        HStack(spacing: 10) {
            if isCleared {
                Label("\(DungeonSystem.repeatGold(dungeon))", systemImage: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                Label("Gear chance", systemImage: "shippingbox.fill")
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Label("\(DungeonSystem.firstClearGold(dungeon))", systemImage: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                Label("\(DungeonSystem.firstClearGems(dungeon))", systemImage: "diamond.fill")
                    .foregroundStyle(Theme.violet)
                Label(LocalizedStringKey(rarity.displayName), systemImage: "shippingbox.fill")
                    .foregroundStyle(rarity.primaryColor)
            }
        }
        .font(.caption2.weight(.semibold))
    }
}
