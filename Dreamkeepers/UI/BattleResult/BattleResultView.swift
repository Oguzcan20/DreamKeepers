import SwiftUI

struct BattleResultView: View {
    let summary: BattleResultSummary
    var gameState: GameState
    var onContinue: () -> Void
    /// Non-nil only after a victory with another stage still ahead — lets
    /// the player chain straight into the next fight instead of always
    /// getting bounced back to Dream Haven between every single stage.
    var onNextBattle: (() -> Void)?

    @State private var appeared = false
    @State private var goldCount = 0
    @State private var expCount = 0

    /// Staggers each reward card's entrance by 90ms per slot so the whole
    /// screen reads as loot dropping in one piece after another, not
    /// everything popping into place at once.
    private func entrance(_ index: Int) -> some ViewModifier { StaggeredEntrance(appeared: appeared, delay: Double(index) * 0.09) }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                if summary.outcome == .victory {
                    VStack(spacing: 12) {
                        if summary.isPerfectClear {
                            perfectClearBanner
                                .modifier(entrance(0))
                        }

                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 12) {
                                rewardsCard
                                    .modifier(entrance(1))
                                if let accountLevelUp = summary.accountLevelUp {
                                    accountLevelUpCard(accountLevelUp)
                                        .modifier(entrance(2))
                                }
                                if let item = summary.droppedEquipment {
                                    droppedEquipmentCard(item)
                                        .modifier(entrance(3))
                                }
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 12) {
                                if !summary.levelUps.isEmpty {
                                    levelUpsCard
                                        .modifier(entrance(2))
                                }
                                if let recruit = summary.newRecruit {
                                    newRecruitCard(recruit)
                                        .modifier(entrance(4))
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    GlassCard {
                        Text("The team regroups at the Dream Tree to try again.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(maxHeight: .infinity)

            if summary.outcome == .victory, let onNextBattle {
                HStack(spacing: 12) {
                    Button("Dream Haven") { onContinue() }
                        .buttonStyle(PrimaryButtonStyle(tint: .gray))
                    Button("Next Battle") { onNextBattle() }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            } else {
                Button(summary.outcome == .victory ? "Continue" : "Return to Dream Haven") {
                    onContinue()
                }
                .buttonStyle(PrimaryButtonStyle(tint: summary.outcome == .victory ? Theme.violet : .gray))
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { appeared = true }
            if summary.outcome == .victory {
                withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
                    goldCount = summary.goldGained
                    expCount = summary.expGained
                }
            }
        }
    }

    /// A gold-ringed banner for a hitless victory — the one bonus worth
    /// calling out above everything else, since it's the rarest thing that
    /// can happen on this screen.
    private var perfectClearBanner: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.7), radius: 12)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Perfect Clear!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text("No damage taken · +\(summary.perfectClearBonusGold) bonus Gold")
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

    private var header: some View {
        VStack(spacing: 8) {
            Group {
                if summary.outcome == .victory {
                    if summary.wasBoss {
                        Text("Boss Defeated!")
                    } else {
                        Text("Victory!")
                    }
                } else {
                    Text("Defeat")
                }
            }
                .font(.title.weight(.heavy))
                .foregroundStyle(summary.outcome == .victory ? Theme.gold : .red)
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
            Text("\(WorldCatalog.world(forStage: summary.stage).name) · Stage \(summary.stage)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var rewardsCard: some View {
        GlassCard {
            HStack(spacing: 24) {
                RewardTile(systemImage: "circle.hexagongrid.fill", value: "+\(goldCount)", tint: Theme.gold)
                RewardTile(systemImage: "star.fill", value: "+\(expCount) EXP", tint: Theme.softBlue)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var levelUpsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Level Up!")
                    .font(.headline)
                    .foregroundStyle(.white)
                ForEach(summary.levelUps) { levelUp in
                    LevelUpRow(levelUp: levelUp)
                }
            }
        }
    }

    private func accountLevelUpCard(_ levelUp: AccountLevelUp) -> some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 48, height: 48)
                        .shadow(color: Theme.gold.opacity(0.6), radius: 10)
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Account Level Up!")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Player Lv \(levelUp.oldLevel) → Lv \(levelUp.newLevel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
            }
        }
    }

    private func droppedEquipmentCard(_ item: EquipmentItem) -> some View {
        GlassCard {
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

    private func newRecruitCard(_ definition: DreamkeeperDefinition) -> some View {
        GlassCard {
            VStack(spacing: 10) {
                Text("A new Dreamkeeper joins you!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.8))
                ZStack {
                    Circle().fill(definition.rarity.gradient).frame(width: 72, height: 72)
                        .shadow(color: definition.element.color.opacity(0.7), radius: 14)
                    Image(systemName: definition.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(definition.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(definition.flavorText))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct RewardTile: View {
    var systemImage: String
    var value: String
    var tint: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).foregroundStyle(tint).font(.title3)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LevelUpRow: View {
    let levelUp: LevelUpSummary

    var body: some View {
        HStack {
            Text(levelUp.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Text("Lv \(levelUp.oldLevel) → Lv \(levelUp.newLevel)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Theme.gold)
        }
    }
}

/// Pops each reward card up and in with a small spring rather than a plain
/// cross-fade — reads as loot dropping onto the screen one piece at a time
/// instead of the whole result appearing all at once.
private struct StaggeredEntrance: ViewModifier {
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
