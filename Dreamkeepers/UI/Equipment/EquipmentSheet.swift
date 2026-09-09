import SwiftUI

struct EquipmentSheet: View {
    let instanceID: UUID
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    private var instance: DreamkeeperInstance? {
        gameState.roster.first { $0.id == instanceID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let instance, let definition = gameState.definition(for: instance) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            header(definition: definition, instance: instance)
                            deployButton(instance: instance)
                            statsGrid(instance: instance)
                            FusionCard(instance: instance, gameState: gameState)
                            Text(LocalizedStringKey(definition.flavorText))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.45))
                                .italic()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 12) {
                            skillsSection(definition: definition)
                            autoEquipButton(instance: instance)
                            ForEach(EquipmentSlot.allCases) { slot in
                                SlotRow(slot: slot, instance: instance, gameState: gameState)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(instance.flatMap { gameState.definition(for: $0)?.name } ?? "Dreamkeeper")
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

    private func header(definition: DreamkeeperDefinition, instance: DreamkeeperInstance) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if DreamkeeperArt.hasArt(for: definition.name) {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    Circle().fill(definition.rarity.gradient).frame(width: 72, height: 72)
                    Image(systemName: definition.symbol).font(.system(size: 30, weight: .semibold)).foregroundStyle(.white)
                }
            }
            Text("Level \(instance.level)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func deployButton(instance: DreamkeeperInstance) -> some View {
        let deployed = gameState.isDeployed(instance)
        return Button(deployed ? "Bench" : "Deploy") {
            gameState.toggleDeployed(instance)
            gameState.playHaptic(.light)
        }
        .buttonStyle(PrimaryButtonStyle(tint: deployed ? .gray : Theme.violet))
    }

    /// `SkillRow.detail` interpolates numbers into a plain `String`, so
    /// `Text` renders it verbatim in whichever language it was written in —
    /// it never reaches `Localizable.xcstrings` no matter how the pieces are
    /// wrapped. Picking the finished sentence directly, like
    /// `GameState.notificationText`, is the only way this reads correctly
    /// in German.
    private var isGerman: Bool {
        gameState.preferredLocale.language.languageCode?.identifier == "de"
    }

    private func localized(en: String, de: String) -> String {
        isGerman ? de : en
    }

    private func skillsSection(definition: DreamkeeperDefinition) -> some View {
        VStack(spacing: 10) {
            SkillRow(icon: "sparkles", tint: Theme.gold, name: definition.ultimate.name,
                     description: definition.ultimate.description,
                     detail: localized(
                        en: "Ultimate · charges after \(definition.ultimate.attacksToCharge) attacks",
                        de: "Ultimate · lädt nach \(definition.ultimate.attacksToCharge) Angriffen"
                     ))
            SkillRow(icon: "bolt.fill", tint: Theme.softBlue, name: definition.activeSkill.name,
                     description: definition.activeSkill.description,
                     detail: localized(
                        en: "Active Skill · \(Int(definition.activeSkill.cooldownSeconds))s cooldown",
                        de: "Aktive Fähigkeit · \(Int(definition.activeSkill.cooldownSeconds)) s Abklingzeit"
                     ))
            SkillRow(icon: "shield.lefthalf.filled", tint: .white.opacity(0.7), name: definition.passive.name,
                     description: definition.passive.description,
                     detail: localized(en: "Passive", de: "Passiv"))
        }
    }

    /// One tap fills every slot with the best unworn item in storage instead
    /// of picking through four "Change" menus by hand. Disabled once nothing
    /// in the bag would actually improve on what's already equipped.
    private func autoEquipButton(instance: DreamkeeperInstance) -> some View {
        Button {
            gameState.autoEquipBest(for: instance)
            gameState.playHaptic(.light)
        } label: {
            Label("Auto-Equip Best Gear", systemImage: "wand.and.stars")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
        .disabled(!gameState.canAutoEquip(instance))
    }

    private func statsGrid(instance: DreamkeeperInstance) -> some View {
        let stats = gameState.currentStats(for: instance)
        return GlassCard {
            HStack {
                StatColumn(label: "HP", value: stats.hp)
                StatColumn(label: "ATK", value: stats.attack)
                StatColumn(label: "DEF", value: stats.defense)
                StatColumn(label: "SPD", value: stats.speed)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct FusionCard: View {
    let instance: DreamkeeperInstance
    var gameState: GameState

    @State private var showPicker: Bool

    /// `DK_AUTO_FUSION_PICKER` opens the picker immediately — QA/screenshot
    /// hook only, no effect unless set.
    init(instance: DreamkeeperInstance, gameState: GameState) {
        self.instance = instance
        self.gameState = gameState
        _showPicker = State(initialValue: ProcessInfo.processInfo.environment["DK_AUTO_FUSION_PICKER"] != nil)
    }

    private var currentInstance: DreamkeeperInstance {
        gameState.roster.first { $0.id == instance.id } ?? instance
    }

    var body: some View {
        GlassCard {
            VStack(spacing: 10) {
                HStack {
                    StarRow(stars: currentInstance.stars, size: .subheadline)
                    Spacer()
                    Image(systemName: "hammer.fill")
                        .foregroundStyle(Theme.gold)
                }

                if currentInstance.stars >= StarFusionSystem.maxStars {
                    Text("Max Stars Reached")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                        .frame(maxWidth: .infinity)
                } else {
                    let cost = StarFusionSystem.duplicatesRequired(forTier: currentInstance.stars + 1)
                    let owned = gameState.duplicates(of: currentInstance).count
                    HStack {
                        Text("\(currentInstance.fusionProgress)/\(cost) banked · \(owned) available")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Spacer()
                        Button("Fuse to ★\(currentInstance.stars + 1)") {
                            showPicker = true
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                        .disabled(owned == 0)
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            FusionPickerView(targetID: instance.id, gameState: gameState)
        }
    }
}

private struct StatColumn: View {
    var label: String
    var value: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.5))
            Text("\(Int(value))").font(.subheadline.monospacedDigit().weight(.semibold)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SkillRow: View {
    let icon: String
    let tint: Color
    let name: String
    let description: String
    let detail: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(description))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
            }
        }
    }
}

private struct SlotRow: View {
    let slot: EquipmentSlot
    let instance: DreamkeeperInstance
    var gameState: GameState

    private var equippedItem: EquipmentItem? {
        gameState.equippedItem(slot, for: instance)
    }

    var body: some View {
        GlassCard {
            HStack {
                Image(systemName: slot.symbol)
                    .foregroundStyle(equippedItem != nil ? Theme.gold : .white.opacity(0.4))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(slot.displayName))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                    Group {
                        if let equippedItem {
                            Text(equippedItem.name)
                        } else {
                            Text("Empty")
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                }

                Spacer()

                Menu {
                    if equippedItem != nil {
                        Button("Unequip", role: .destructive) {
                            gameState.unequip(slot, from: instance)
                            gameState.playHaptic(.light)
                        }
                    }
                    let available = gameState.availableItems(for: slot)
                    if available.isEmpty {
                        Text("No items in inventory")
                    } else {
                        ForEach(available) { item in
                            Button {
                                gameState.equip(item, to: instance)
                                gameState.playHaptic(.light)
                            } label: {
                                Text(item.name) + Text(" (") + Text(LocalizedStringKey(item.rarity.displayName)) + Text(")")
                            }
                        }
                    }
                } label: {
                    Text("Change")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.softBlue)
                }
            }
        }
    }
}
