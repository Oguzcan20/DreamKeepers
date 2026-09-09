import SwiftUI

/// Manual fusion flow for Equipment — mirrors `FusionPickerView` for
/// Dreamkeepers. Shows every owned duplicate of the same item kind (slot +
/// name + rarity) so the player picks exactly which copies to feed in.
struct ItemFusionPickerView: View {
    let targetID: UUID
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIDs: Set<UUID> = []
    @State private var justFused = false
    @State private var lastFuseGrantedStar = false

    private var target: EquipmentItem? {
        gameState.inventory.first { $0.id == targetID }
    }

    private var duplicates: [EquipmentItem] {
        target.map { gameState.duplicates(ofItem: $0) } ?? []
    }

    private var cost: Int? {
        target.flatMap { gameState.nextFusionCost(forItem: $0) }
    }

    /// Banked progress plus whatever's selected right now.
    private var bankedTotal: Int {
        (target?.fusionProgress ?? 0) + selectedIDs.count
    }

    /// Whether fusing right now would actually cross into the next star.
    private var willStarUp: Bool {
        guard let cost else { return false }
        return bankedTotal >= cost
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let target {
                    if let cost {
                        content(target: target, cost: cost)
                    } else {
                        maxedState(target: target)
                    }
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Fuse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func content(target: EquipmentItem, cost: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(target: target)
                progressCard(cost: cost)
                if willStarUp {
                    statsPreviewCard(target: target)
                }

                if duplicates.isEmpty {
                    GlassCard {
                        Text("No duplicate \(target.name)s yet. Clear more stages to find fusion fodder.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Select duplicates to fuse")
                            .font(.headline)
                            .foregroundStyle(.white)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                            ForEach(duplicates) { duplicate in
                                ItemDuplicatePickerCard(
                                    item: duplicate,
                                    isSelected: selectedIDs.contains(duplicate.id)
                                ) {
                                    toggle(duplicate.id)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }

        footer(target: target, cost: cost)
    }

    private func progressCard(cost: Int) -> some View {
        GlassCard {
            VStack(spacing: 8) {
                Text("\(bankedTotal)/\(cost) toward next star")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .overlay(alignment: .leading) {
                            Capsule()
                                .fill(willStarUp ? Theme.gold : Theme.violet)
                                .frame(width: geo.size.width * min(1, Double(bankedTotal) / Double(cost)))
                        }
                }
                .frame(height: 8)
            }
        }
    }

    private func header(target: EquipmentItem) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if ItemArt.hasArt(for: target.name) {
                    Image(ItemArt.assetName(for: target.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(target.rarity.gradient, lineWidth: 3))
                } else {
                    Circle().fill(target.rarity.gradient).frame(width: 64, height: 64)
                    Image(systemName: target.slot.symbol).font(.system(size: 26, weight: .semibold)).foregroundStyle(.white)
                }
            }
            Text(target.name)
                .font(.headline)
                .foregroundStyle(.white)
            StarRow(stars: target.stars, size: .subheadline)
        }
    }

    private func statsPreviewCard(target: EquipmentItem) -> some View {
        var preview = target
        preview.stars += 1
        let before = target.effectiveStatBonus
        let after = preview.effectiveStatBonus
        return GlassCard {
            VStack(spacing: 10) {
                Text("Fusing to ★\(target.stars + 1) grants")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
                HStack {
                    StatDeltaColumn(label: "HP", before: before.hp, after: after.hp)
                    StatDeltaColumn(label: "ATK", before: before.attack, after: after.attack)
                    StatDeltaColumn(label: "DEF", before: before.defense, after: after.defense)
                    StatDeltaColumn(label: "SPD", before: before.speed, after: after.speed)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func footer(target: EquipmentItem, cost: Int) -> some View {
        VStack(spacing: 8) {
            Text("\(selectedIDs.count) selected")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.6))
            Button(justFused ? (lastFuseGrantedStar ? "Star Up!" : "Fused!") : "Fuse") {
                fuse(target: target)
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
            .disabled(selectedIDs.isEmpty || justFused)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Theme.deepNavy)
    }

    private func maxedState(target: EquipmentItem) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)
            Text("\(target.name) is at max stars")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
        gameState.playHaptic(.light)
    }

    private func fuse(target: EquipmentItem) {
        let selected = duplicates.filter { selectedIDs.contains($0.id) }
        let grantsStar = willStarUp
        guard gameState.fuseItem(target, consuming: selected) else { return }
        gameState.playSound(.levelUp)
        gameState.playHaptic(.levelUp)
        lastFuseGrantedStar = grantsStar
        justFused = true
        selectedIDs.removeAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            justFused = false
        }
    }
}

private struct StatDeltaColumn: View {
    var label: String
    var before: Double
    var after: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
            Text("\(Int(before))").font(.caption.monospacedDigit()).foregroundStyle(.white.opacity(0.5))
            Text("+\(Int(after - before))")
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(Theme.gold)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ItemDuplicatePickerCard: View {
    let item: EquipmentItem
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if ItemArt.hasArt(for: item.name) {
                    Image(ItemArt.assetName(for: item.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(item.rarity.gradient, lineWidth: 2.5))
                } else {
                    Circle()
                        .fill(item.rarity.gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: item.slot.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                if isSelected {
                    Circle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.gold)
                }
            }
            Text("Lv \(item.level)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Theme.gold.opacity(0.18) : Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isSelected ? Theme.gold : Theme.cardStroke, lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onTap)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
