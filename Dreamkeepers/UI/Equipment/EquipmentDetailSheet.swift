import SwiftUI

/// Tap-to-open detail window for an inventory item — mirrors `EquipmentSheet`
/// for Dreamkeepers: stats, upgrade, and fusion all live in one place instead
/// of being split across separate screens — stats, fusion, and upgrade all
/// live here.
struct EquipmentDetailSheet: View {
    let itemID: UUID
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var item: EquipmentItem? {
        gameState.inventory.first { $0.id == itemID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let item {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            header(item: item)
                            statsGrid(item: item)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            FusionCard(itemID: item.id, gameState: gameState)
                            upgradeCard(item: item)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(item?.name ?? "Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func header(item: EquipmentItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if ItemArt.hasArt(for: item.name) {
                    Image(ItemArt.assetName(for: item.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(item.rarity.gradient, lineWidth: 3))
                } else {
                    Circle().fill(item.rarity.gradient).frame(width: 72, height: 72)
                    Image(systemName: item.slot.symbol).font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
                }
            }
            (Text(LocalizedStringKey(item.rarity.displayName)) + Text(" · Lv \(item.level)/\(EquipmentUpgrade.maxLevel)"))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            if let wearerName = gameState.wearer(of: item).flatMap({ gameState.definition(for: $0)?.name }) {
                Text("Worn by \(wearerName)")
                    .font(.caption)
                    .foregroundStyle(Theme.softBlue)
            }
        }
    }

    private func statsGrid(item: EquipmentItem) -> some View {
        let bonus = item.effectiveStatBonus
        return GlassCard {
            HStack {
                StatColumn(label: "HP", value: bonus.hp)
                StatColumn(label: "ATK", value: bonus.attack)
                StatColumn(label: "DEF", value: bonus.defense)
                StatColumn(label: "SPD", value: bonus.speed)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func upgradeCard(item: EquipmentItem) -> some View {
        let isMaxed = !EquipmentUpgrade.canUpgrade(item)
        let canAfford = gameState.save.gold >= EquipmentUpgrade.cost(for: item)
        return GlassCard {
            if isMaxed {
                Text("Max Level Reached")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.gold)
                    .frame(maxWidth: .infinity)
            } else {
                HStack {
                    Text("\(EquipmentUpgrade.cost(for: item)) Gold")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Spacer()
                    Button("Upgrade") {
                        gameState.upgradeEquipment(item)
                        gameState.playHaptic(.light)
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    .disabled(!canAfford)
                }
            }
        }
    }
}

private struct FusionCard: View {
    let itemID: UUID
    var gameState: GameState

    @State private var showPicker = false

    private var currentItem: EquipmentItem? {
        gameState.inventory.first { $0.id == itemID }
    }

    var body: some View {
        if let currentItem {
            GlassCard {
                VStack(spacing: 10) {
                    HStack {
                        StarRow(stars: currentItem.stars, size: .subheadline)
                        Spacer()
                        Image(systemName: "hammer.fill")
                            .foregroundStyle(Theme.gold)
                    }

                    if currentItem.stars >= StarFusionSystem.maxStars {
                        Text("Max Stars Reached")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                            .frame(maxWidth: .infinity)
                    } else {
                        let cost = StarFusionSystem.duplicatesRequired(forTier: currentItem.stars + 1)
                        let owned = gameState.duplicates(ofItem: currentItem).count
                        HStack {
                            Text("\(currentItem.fusionProgress)/\(cost) banked · \(owned) available")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                            Spacer()
                            Button("Fuse to ★\(currentItem.stars + 1)") {
                                showPicker = true
                            }
                            .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                            .disabled(owned == 0)
                        }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                ItemFusionPickerView(targetID: itemID, gameState: gameState)
            }
        }
    }
}

private struct StatColumn: View {
    var label: String
    var value: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
            Text("+\(Int(value))").font(.subheadline.monospacedDigit().weight(.semibold)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}
