import SwiftUI

/// Result screen for one Dungeon run ("Schlünde") — mirrors
/// `ArenaResultView`'s visual language, swapping the floor number for the
/// dungeon's name and adding a Dream Gems line alongside gold since a first
/// clear grants both.
struct DungeonResultView: View {
    let summary: DungeonBattleResultSummary
    /// Jumps back into the Dungeon hub to run another key (or retry after a loss).
    var onFightAgain: () -> Void
    var onDreamHaven: () -> Void

    @State private var appeared = false

    private var won: Bool { summary.outcome == .victory }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    if summary.isFirstClear {
                        firstClearBanner
                            .modifier(entrance(0))
                    }

                    if won {
                        rewardCard
                            .modifier(entrance(1))
                    }

                    if let item = summary.droppedEquipment {
                        droppedEquipmentCard(item)
                            .modifier(entrance(2))
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Dream Haven") { onDreamHaven() }
                    .buttonStyle(PrimaryButtonStyle(tint: .gray))
                Button("Back to Dungeons") { onFightAgain() }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private func entrance(_ index: Int) -> some ViewModifier { ArenaStaggeredEntrance(appeared: appeared, delay: Double(index) * 0.09) }

    private var header: some View {
        VStack(spacing: 8) {
            Text(won ? "Victory!" : "Defeat")
                .font(.title.weight(.heavy))
                .foregroundStyle(won ? Theme.gold : .red)
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
            Text(DungeonSystem.displayName(summary.dungeon))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var firstClearBanner: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.7), radius: 12)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("First Clear!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text("A guaranteed rare reward for clearing this Dungeon for the first time.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.gold.opacity(0.3), radius: 14, y: 4)
    }

    private var rewardCard: some View {
        GlassCard {
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundStyle(Theme.gold)
                        .font(.title3)
                    Text("+\(summary.goldGained) Gold")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                if summary.gemsGained > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "diamond.fill")
                            .foregroundStyle(Theme.violet)
                            .font(.title3)
                        Text("+\(summary.gemsGained) Gems")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func droppedEquipmentCard(_ item: EquipmentItem) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(summary.isFirstClear ? "First Clear Reward" : "Standard Reward")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(summary.isFirstClear ? Theme.gold : .white.opacity(0.55))
                HStack(spacing: 14) {
                    ZStack {
                        if ItemArt.hasArt(for: item.name) {
                            Image(ItemArt.assetName(for: item.name))
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(item.rarity.gradient, lineWidth: 2.5))
                        } else {
                            Circle().fill(item.rarity.gradient).frame(width: 48, height: 48)
                            Image(systemName: item.slot.symbol)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(item.rarity.displayName)) + Text(" · ") + Text(LocalizedStringKey(item.slot.displayName))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                }
            }
        }
    }
}

private struct ArenaStaggeredEntrance: ViewModifier {
    let appeared: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.85)
            .offset(y: appeared ? 0 : 22)
            .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(delay), value: appeared)
    }
}
