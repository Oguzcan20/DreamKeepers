import SwiftUI

/// The single hub for "everything the player owns" — Dreamkeepers (with team
/// deploy/bench) and Items in one place, reachable from one entry point.
/// Spec screens #7 (Dreamkeeper Collection) and #9 (Equipment) live here
/// side by side instead of two separately-discovered screens.
struct InventoryView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    private enum Tab: String, CaseIterable, Identifiable {
        case dreamkeepers = "Dreamkeepers"
        case items = "Items"
        var id: String { rawValue }
    }

    private enum RosterSort: String, CaseIterable, Identifiable {
        case level, rarity, stars, attack

        var id: String { rawValue }

        var label: String {
            switch self {
            case .level: return "Level"
            case .rarity: return "Rarity"
            case .stars: return "Stars"
            case .attack: return "Attack"
            }
        }

        var symbol: String {
            switch self {
            case .level: return "arrow.up.forward"
            case .rarity: return "sparkles"
            case .stars: return "star.fill"
            case .attack: return "bolt.fill"
            }
        }
    }

    @State private var tab: Tab = .dreamkeepers
    @State private var equipmentTarget: DreamkeeperInstance?
    @State private var itemTarget: EquipmentItem?
    @State private var rosterSort: RosterSort = .level
    @State private var sellMode = false
    @State private var selectedForSale: Set<UUID> = []
    @State private var showSellConfirm = false

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    /// `DK_AUTO_GEAR` opens the first roster member's equip sheet immediately,
    /// `DK_AUTO_ITEM` does the same for the first inventory item — QA/screenshot
    /// hooks only, no effect unless set.
    init(gameState: GameState, navigate: @escaping (AppRoute) -> Void) {
        self.gameState = gameState
        self.navigate = navigate
        if ProcessInfo.processInfo.environment["DK_AUTO_GEAR"] != nil, let first = gameState.roster.first {
            _equipmentTarget = State(initialValue: first)
        }
        if ProcessInfo.processInfo.environment["DK_AUTO_ITEM"] != nil, let first = gameState.inventory.first {
            _itemTarget = State(initialValue: first)
        }
        if ProcessInfo.processInfo.environment["DK_INVENTORY_TAB"] == "items" {
            _tab = State(initialValue: .items)
        }
    }

    @State private var appeared = false

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.softBlue, bottomTint: Theme.violet)

            VStack(spacing: 0) {
                header
                picker

                switch tab {
                case .dreamkeepers:
                    dreamkeepersTab
                case .items:
                    itemsTab
                }
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .sheet(item: $equipmentTarget) { target in
            EquipmentSheet(instanceID: target.id, gameState: gameState)
        }
        .sheet(item: $itemTarget) { target in
            EquipmentDetailSheet(itemID: target.id, gameState: gameState)
        }
        .confirmationDialog(
            selectedForSale.count == 1 ? "Sell 1 Dreamkeeper?" : "Sell \(selectedForSale.count) Dreamkeepers?",
            isPresented: $showSellConfirm,
            titleVisibility: .visible
        ) {
            let value = sellTotal
            Button(role: .destructive) {
                gameState.sellDreamkeepers(selectedForSale)
                gameState.playHaptic(.success)
                withAnimation {
                    sellMode = false
                    selectedForSale.removeAll()
                }
            } label: {
                if value.gems > 0 {
                    Text("Sell for \(value.gold) Gold + \(value.gems) Gems")
                } else {
                    Text("Sell for \(value.gold) Gold")
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone. Equipped gear is unequipped, not sold.")
        }
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
            Text("Inventory")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                navigate(.codex)
            } label: {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Dreamkeeper Codex")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var picker: some View {
        Picker("Tab", selection: $tab) {
            ForEach(Tab.allCases) { tab in
                Text(LocalizedStringKey(tab.rawValue)).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Dreamkeepers

    /// Roster ordered by the chosen `rosterSort` metric, richest/highest
    /// first; a name tiebreak keeps the order stable instead of shuffling
    /// arbitrarily whenever two Dreamkeepers tie on the sorted metric.
    private var sortedRoster: [DreamkeeperInstance] {
        gameState.roster.sorted { a, b in
            let defA = gameState.definition(for: a)
            let defB = gameState.definition(for: b)
            switch rosterSort {
            case .level:
                if a.level != b.level { return a.level > b.level }
            case .rarity:
                let rarityA = defA?.rarity ?? .common
                let rarityB = defB?.rarity ?? .common
                if rarityA != rarityB { return rarityA > rarityB }
            case .stars:
                if a.stars != b.stars { return a.stars > b.stars }
            case .attack:
                let attackA = gameState.currentStats(for: a).attack
                let attackB = gameState.currentStats(for: b).attack
                if attackA != attackB { return attackA > attackB }
            }
            return (defA?.name ?? "") < (defB?.name ?? "")
        }
    }

    private var dreamkeepersTab: some View {
        VStack(spacing: 0) {
            teamPicker
                .padding(.top, 10)

            Group {
                if sellMode {
                    sellBar
                } else {
                    HStack {
                        Text("Tap a Dreamkeeper to view stats and fusion.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        sellModeButton
                        sortMenu
                        Text("\(gameState.deployedTeam.count)/\(Team.maxSize) deployed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.gold)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(sortedRoster) { instance in
                        if let def = gameState.definition(for: instance) {
                            DreamkeeperCard(
                                definition: def, instance: instance,
                                isDeployed: gameState.isDeployed(instance),
                                isSelectedForSale: sellMode ? selectedForSale.contains(instance.id) : nil,
                                twinBondActive: TwinBond.isBondCharacter(instance.definitionID)
                                    ? TwinBond.isActive(memberDefinitionIDs: gameState.deployedTeam.map(\.definitionID))
                                    : nil,
                                onTap: {
                                    if sellMode {
                                        toggleSaleSelection(instance)
                                    } else {
                                        equipmentTarget = instance
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(20)
            }
        }
    }

    private var sellModeButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                sellMode = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                Text("Sell")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Sell Dreamkeepers")
    }

    /// Replaces the normal "tap to view stats" row while `sellMode` is
    /// active — shows the running payout for whatever's currently checked
    /// and lets the player back out without selling anything.
    private var sellBar: some View {
        let value = sellTotal
        return HStack {
            Button("Cancel") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    sellMode = false
                    selectedForSale.removeAll()
                }
            }
            .foregroundStyle(.white.opacity(0.75))

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(selectedForSale.count) selected")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                if !selectedForSale.isEmpty {
                    Text(value.gems > 0 ? "+\(value.gold) Gold · +\(value.gems) Gems" : "+\(value.gold) Gold")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }
            }

            Button("Sell") {
                showSellConfirm = true
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
            .disabled(selectedForSale.isEmpty)
            .padding(.leading, 10)
        }
    }

    private var sellTotal: (gold: Int, gems: Int) {
        selectedForSale.reduce((gold: 0, gems: 0)) { total, id in
            guard let instance = gameState.roster.first(where: { $0.id == id }) else { return total }
            let value = gameState.sellValue(for: instance)
            return (total.gold + value.gold, total.gems + value.gems)
        }
    }

    private func toggleSaleSelection(_ instance: DreamkeeperInstance) {
        guard gameState.canSellDreamkeeper(instance) else { return }
        if selectedForSale.contains(instance.id) {
            selectedForSale.remove(instance.id)
        } else {
            selectedForSale.insert(instance.id)
        }
        gameState.playHaptic(.light)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(RosterSort.allCases) { option in
                Button {
                    rosterSort = option
                } label: {
                    Label(LocalizedStringKey(option.label), systemImage: option.symbol)
                    if rosterSort == option {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(LocalizedStringKey(rosterSort.label))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .accessibilityLabel("Sort Dreamkeepers")
    }

    private var teamPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(gameState.teams) { team in
                    TeamChip(
                        team: team,
                        isActive: team.id == gameState.activeTeamID,
                        onTap: {
                            gameState.setActiveTeam(team.id)
                            gameState.playHaptic(.light)
                        }
                    )
                }
                if gameState.teams.count < GameState.maxTeams {
                    Button {
                        gameState.createTeam()
                        gameState.playHaptic(.light)
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Create Team")
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Items

    private var itemsBySlot: [(slot: EquipmentSlot, items: [EquipmentItem])] {
        EquipmentSlot.allCases.map { slot in
            (slot, gameState.inventory
                .filter { $0.slot == slot }
                .sorted { $0.rarity == $1.rarity ? $0.level > $1.level : $0.rarity > $1.rarity })
        }
    }

    private var itemsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if gameState.inventory.isEmpty {
                    // Landscape leaves a lot of open canvas below a lone
                    // small card, which used to just trail off into empty
                    // background — a real CTA gives the empty state
                    // somewhere to send the player instead of a dead end.
                    emptyItemsCallout
                } else {
                    ForEach(itemsBySlot, id: \.slot) { group in
                        if !group.items.isEmpty {
                            itemSlotSection(slot: group.slot, items: group.items)
                        }
                    }
                }
            }
            .padding(20)
        }
    }

    private var emptyItemsCallout: some View {
        GlassCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.softBlue.opacity(0.16)).frame(width: 68, height: 68)
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.softBlue)
                }
                VStack(spacing: 4) {
                    Text("No Items Yet")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Clear a campaign stage to find equipment for your Dreamkeepers.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button {
                    navigate(.campaign)
                } label: {
                    Label("Go to Campaign", systemImage: "map.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.softBlue))
                .frame(maxWidth: 220)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.top, 40)
    }

    private func itemSlotSection(slot: EquipmentSlot, items: [EquipmentItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(LocalizedStringKey(slot.displayName), systemImage: slot.symbol)
                .font(.headline)
                .foregroundStyle(.white)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    InventoryItemRow(
                        item: item, gameState: gameState,
                        wearerName: gameState.wearer(of: item).flatMap { gameState.definition(for: $0)?.name },
                        onTap: { itemTarget = item }
                    )
                }
            }
        }
    }
}

private struct InventoryItemRow: View {
    let item: EquipmentItem
    var gameState: GameState
    let wearerName: String?
    var onTap: () -> Void

    var body: some View {
        // Real `Button`, not `.onTapGesture` — same VoiceOver-exposure fix
        // as `battlePassBanner` in `DreamHavenView`. `.plain` preserves the
        // row's own look; the combined accessibility element speaks name,
        // rarity, level and wearer as one row instead of scattered children.
        Button(action: onTap) {
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

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(item.rarity.displayName)) + Text(" · Lv \(item.level)/\(EquipmentUpgrade.maxLevel)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                        StarRow(stars: item.stars, size: .caption2)
                        Group {
                            if let wearerName {
                                Text("Worn by \(wearerName)")
                            } else {
                                Text("In storage")
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(wearerName != nil ? Theme.softBlue : .white.opacity(0.4))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct TeamChip: View {
    let team: Team
    let isActive: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(LocalizedStringKey(team.name))
                    .font(.caption.weight(.semibold))
                Text("\(team.memberIDs.count)/\(Team.maxSize)")
                    .font(.caption2)
                    .opacity(0.7)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Theme.violet.opacity(0.35) : Color.white.opacity(0.06))
            .overlay(
                Capsule().stroke(isActive ? Theme.gold : Theme.cardStroke, lineWidth: isActive ? 2 : 1)
            )
            .clipShape(Capsule())
        }
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
