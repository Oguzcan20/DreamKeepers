import SwiftUI

/// Result screen for one Arena Tower floor fight — reuses
/// `BattleResultView`'s reward-card visual language (equipment drop, new
/// recruit) since a win here can grant the exact same kinds of loot, just
/// scaled by floor instead of by campaign stage.
struct ArenaResultView: View {
    let summary: ArenaBattleResultSummary
    /// Jumps back into the Arena hub to face the next floor (or retry the
    /// current one after a loss).
    var onFightAgain: () -> Void
    var onDreamHaven: () -> Void

    @State private var appeared = false

    private var won: Bool { summary.outcome == .victory }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    if summary.towerCleared {
                        towerClearedBanner
                            .modifier(entrance(0))
                    } else if won, summary.isMilestoneFloor {
                        milestoneBanner
                            .modifier(entrance(0))
                    }

                    if won {
                        goldCard
                            .modifier(entrance(1))
                    }

                    if summary.tierChanged {
                        tierChangeCard
                            .modifier(entrance(2))
                    }

                    if let item = summary.droppedEquipment {
                        droppedEquipmentCard(item)
                            .modifier(entrance(3))
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button("Dream Haven") { onDreamHaven() }
                    .buttonStyle(PrimaryButtonStyle(tint: .gray))
                if !summary.towerCleared {
                    Button("Fight Again") { onFightAgain() }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                }
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
            Group {
                Text(won ? "Victory!" : "Defeat")
            }
            .font(.title.weight(.heavy))
            .foregroundStyle(won ? Theme.gold : .red)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            Text("Floor \(summary.floor)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var towerClearedBanner: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.7), radius: 12)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tower Cleared!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text("You've conquered all 100 floors of the Arena Tower.")
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

    private var milestoneBanner: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.7), radius: 12)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Milestone Reward!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text("A guaranteed Legendary reward for reaching this floor.")
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

    private var goldCard: some View {
        GlassCard {
            HStack(spacing: 6) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                    .font(.title3)
                Text("+\(summary.goldGained) Gold")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var tierChangeCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.6), radius: 10)
                    Image(systemName: summary.newTier.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("New Tier!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(summary.newTier.displayName))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
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
