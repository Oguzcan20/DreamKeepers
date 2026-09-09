import SwiftUI

/// Manual fusion flow (spec: player-driven, not automatic). Shows every
/// owned duplicate of the target species so the player picks exactly which
/// copies to feed in, previews the stat gain, then confirms.
struct FusionPickerView: View {
    let targetID: UUID
    var gameState: GameState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedIDs: Set<UUID> = []
    @State private var justFused = false
    @State private var lastFuseGrantedStar = false

    /// Set only when a fuse actually crosses into a new star (not just
    /// banks progress toward one) — the moment worth a full-screen cutscene
    /// rather than the footer button's quiet "Star Up!" label alone.
    @State private var showcase: StarUpShowcaseData?

    private var target: DreamkeeperInstance? {
        gameState.roster.first { $0.id == targetID }
    }

    private var duplicates: [DreamkeeperInstance] {
        target.map { gameState.duplicates(of: $0) } ?? []
    }

    private var cost: Int? {
        target.flatMap { gameState.nextFusionCost(for: $0) }
    }

    /// Banked progress plus whatever's selected right now — the number a
    /// fuse would actually consume if pressed this instant.
    private var bankedTotal: Int {
        (target?.fusionProgress ?? 0) + selectedIDs.count
    }

    /// Whether fusing right now would actually cross into the next star, as
    /// opposed to just banking progress toward it.
    private var willStarUp: Bool {
        guard let cost else { return false }
        return bankedTotal >= cost
    }

    private var statsAfter: Stats? {
        guard let target else { return nil }
        var preview = target
        preview.stars += 1
        return gameState.currentStats(for: preview)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    if let target, let definition = gameState.definition(for: target) {
                        if let cost {
                            content(target: target, definition: definition, cost: cost)
                        } else {
                            maxedState(definition: definition)
                        }
                    }
                }

                if let showcase {
                    StarUpShowcase(data: showcase) {
                        withAnimation(.easeIn(duration: 0.2)) { self.showcase = nil }
                    }
                    .zIndex(1)
                    .transition(.opacity)
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
    private func content(target: DreamkeeperInstance, definition: DreamkeeperDefinition, cost: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(target: target, definition: definition)
                progressCard(cost: cost)
                if willStarUp {
                    statsPreviewCard(target: target)
                }

                if duplicates.isEmpty {
                    GlassCard {
                        Text("No duplicate \(definition.name)s yet. Summon more to gather fusion fodder.")
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
                                DuplicatePickerCard(
                                    definition: definition, instance: duplicate,
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

    /// Always-visible banked-progress readout — the whole point of banking
    /// is that the player can fuse whatever they have right now and see
    /// exactly how close that gets them, instead of the button just staying
    /// disabled with no explanation until they happen to have the full cost.
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

    private func header(target: DreamkeeperInstance, definition: DreamkeeperDefinition) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if DreamkeeperArt.hasArt(for: definition.name) {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                } else {
                    Circle().fill(definition.rarity.gradient).frame(width: 64, height: 64)
                    Image(systemName: definition.symbol).font(.system(size: 26, weight: .semibold)).foregroundStyle(.white)
                }
            }
            Text(definition.name)
                .font(.headline)
                .foregroundStyle(.white)
            StarRow(stars: target.stars, size: .subheadline)
        }
    }

    private func statsPreviewCard(target: DreamkeeperInstance) -> some View {
        let before = gameState.currentStats(for: target)
        let after = statsAfter ?? before
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

    private func footer(target: DreamkeeperInstance, cost: Int) -> some View {
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

    private func maxedState(definition: DreamkeeperDefinition) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gold)
            Text("\(definition.name) is at max stars")
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

    private func fuse(target: DreamkeeperInstance) {
        let selected = duplicates.filter { selectedIDs.contains($0.id) }
        let grantsStar = willStarUp
        let statsBefore = gameState.currentStats(for: target)
        guard gameState.fuseDreamkeeper(target, consuming: selected) else { return }
        gameState.playSound(.levelUp)
        gameState.playHaptic(.levelUp)
        lastFuseGrantedStar = grantsStar
        justFused = true
        selectedIDs.removeAll()

        if grantsStar, let definition = gameState.definition(for: target),
           let updated = gameState.roster.first(where: { $0.id == target.id }) {
            let statsAfter = gameState.currentStats(for: updated)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.25)) {
                    showcase = StarUpShowcaseData(
                        definition: definition, newStars: updated.stars,
                        statsBefore: statsBefore, statsAfter: statsAfter
                    )
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            justFused = false
        }
    }
}

private struct StarUpShowcaseData {
    let definition: DreamkeeperDefinition
    let newStars: Int
    let statsBefore: Stats
    let statsAfter: Stats
}

/// Full-screen cutscene for an actual star-up (not just banked progress) —
/// dimmed background, a spinning gold ring around the portrait, the new
/// star row, and the stat gains flying in, mirroring the same "big moment"
/// language as the battle Ultimate showcase and the summon reveal. Tap
/// anywhere to dismiss early.
private struct StarUpShowcase: View {
    let data: StarUpShowcaseData
    var onDismiss: () -> Void

    @State private var portraitScale: CGFloat = 0.3
    @State private var portraitOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0
    @State private var statsOpacity: Double = 0

    private var definition: DreamkeeperDefinition { data.definition }
    private var portraitSize: CGFloat { 170 }
    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Circle()
                .fill(definition.element.color.opacity(0.45))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .opacity(glowOpacity)

            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10, 8]))
                .foregroundStyle(Theme.gold.opacity(0.85))
                .frame(width: portraitSize + 30, height: portraitSize + 30)
                .rotationEffect(.degrees(ringRotation))
                .opacity(ringOpacity)

            VStack(spacing: 14) {
                ZStack {
                    if hasArt {
                        Image(DreamkeeperArt.assetName(for: definition.name))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: portraitSize, height: portraitSize)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(definition.rarity.gradient).frame(width: portraitSize, height: portraitSize)
                        Image(systemName: definition.symbol)
                            .font(.system(size: portraitSize * 0.4, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(Circle().strokeBorder(Theme.gold, lineWidth: 5))
                .shadow(color: Theme.gold.opacity(0.85), radius: 30)
                .scaleEffect(portraitScale)
                .opacity(portraitOpacity)

                VStack(spacing: 6) {
                    Text("STAR UP!")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: Theme.gold.opacity(0.8), radius: 10)
                    Text(definition.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    StarRow(stars: data.newStars, size: .title3)
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)

                HStack(spacing: 18) {
                    StatDeltaColumn(label: "HP", before: data.statsBefore.hp, after: data.statsAfter.hp)
                    StatDeltaColumn(label: "ATK", before: data.statsBefore.attack, after: data.statsAfter.attack)
                    StatDeltaColumn(label: "DEF", before: data.statsBefore.defense, after: data.statsAfter.defense)
                    StatDeltaColumn(label: "SPD", before: data.statsBefore.speed, after: data.statsAfter.speed)
                }
                .opacity(statsOpacity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 14)) {
                portraitScale = 1
                portraitOpacity = 1
                glowOpacity = 1
                ringOpacity = 1
            }
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    titleScale = 1
                    titleOpacity = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                withAnimation(.easeOut(duration: 0.4)) { statsOpacity = 1 }
            }
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

private struct DuplicatePickerCard: View {
    let definition: DreamkeeperDefinition
    let instance: DreamkeeperInstance
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if DreamkeeperArt.hasArt(for: definition.name) {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(definition.rarity.gradient)
                        .frame(width: 48, height: 48)
                    Image(systemName: definition.symbol)
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
            Text("Lv \(instance.level)")
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
