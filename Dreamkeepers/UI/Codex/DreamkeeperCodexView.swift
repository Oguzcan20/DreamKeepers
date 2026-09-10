import SwiftUI

/// Dreamkeeper Codex — a full reference for every Dreamkeeper in the game,
/// owned or not. Unlike the Dream Observatory's enemy bestiary (which stays
/// silhouetted until discovered in battle), every entry here shows its full
/// art, stats and lore up front: the Summoning Shrine already shows exact
/// odds with "no hidden mechanics" (see `SummonSystem`), so hiding a
/// Dreamkeeper's own details behind ownership would just be inconsistent
/// with that. Ownership is shown as a badge, not a lock.
struct DreamkeeperCodexView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    private enum ElementFilter: Hashable {
        case all
        case element(Element)
    }

    @State private var elementFilter: ElementFilter = .all
    @State private var roleFilter: Role?
    @State private var selectedDefinition: DreamkeeperDefinition?
    @State private var appeared = false

    private var catalog: DreamkeeperCatalog { gameState.catalog }

    private var filteredDefinitions: [DreamkeeperDefinition] {
        catalog.definitions
            .filter { def in
                switch elementFilter {
                case .all: return true
                case .element(let element): return def.element == element
                }
            }
            .filter { roleFilter == nil || $0.role == roleFilter }
            .sorted { lhs, rhs in
                lhs.rarity == rhs.rarity ? lhs.name < rhs.name : lhs.rarity > rhs.rarity
            }
    }

    private func isOwned(_ definition: DreamkeeperDefinition) -> Bool {
        gameState.roster.contains { $0.definitionID == definition.id }
    }

    private func ownedCount(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.count
    }

    private func maxStars(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.map(\.stars).max() ?? 0
    }

    /// The real visible content region (screen bounds minus safe-area
    /// insets), matching the same forced-sizing pattern used elsewhere in
    /// this app (`SummoningShrineView`, `MultiSummonResultView`) to sidestep
    /// a recurring SwiftUI layout-proposal bug on this landscape-locked app.
    ///
    /// Uses `dk_safeContentSize` rather than raw `UIScreen.main.bounds`:
    /// raw bounds includes the notch / Dynamic Island and home-indicator
    /// strips, so force-fitting to it made this view taller than the slot
    /// `RootView` gives it — SwiftUI then centred it and clipped the header
    /// (and its back button) a few points off the top edge.
    private var screenSize: CGSize { UIScreen.dk_safeContentSize }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                filterBar
                grid
            }
            .opacity(appeared ? 1 : 0)

            if let selectedDefinition {
                DreamkeeperCodexDetailView(
                    definition: selectedDefinition,
                    isOwned: isOwned(selectedDefinition),
                    ownedCount: ownedCount(selectedDefinition),
                    maxStars: maxStars(selectedDefinition),
                    gameState: gameState
                ) {
                    withAnimation(.easeOut(duration: 0.2)) { self.selectedDefinition = nil }
                }
                .zIndex(1)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
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
            VStack(spacing: 2) {
                Text("Dreamkeeper Codex")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(gameState.ownedSpeciesCount)/\(catalog.definitions.count) Collected")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Color.clear.frame(width: 40, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ElementChip(title: "All", color: .white, isSelected: elementFilter == .all) {
                        elementFilter = .all
                    }
                    ForEach(Element.allCases) { element in
                        ElementChip(
                            title: element.displayName, symbol: element.symbol, color: element.color,
                            isSelected: elementFilter == .element(element)
                        ) {
                            elementFilter = .element(element)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            Menu {
                Button("All Roles") { roleFilter = nil }
                ForEach(Role.allCases) { role in
                    Button {
                        roleFilter = role
                    } label: {
                        Label(LocalizedStringKey(role.displayName), systemImage: role.symbol)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: roleFilter?.symbol ?? "line.3.horizontal.decrease.circle")
                    Text(LocalizedStringKey(roleFilter?.displayName ?? "All Roles"))
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .accessibilityLabel("Filter by Role")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 108), spacing: 12)], spacing: 12) {
                ForEach(filteredDefinitions) { definition in
                    CodexCard(
                        definition: definition,
                        isOwned: isOwned(definition),
                        ownedCount: ownedCount(definition),
                        maxStars: maxStars(definition)
                    )
                    .onTapGesture {
                        gameState.playHaptic(.light)
                        selectedDefinition = definition
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 30)
        }
    }
}

private struct ElementChip: View {
    var title: String
    var symbol: String?
    var color: Color
    var isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 5) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(LocalizedStringKey(title))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .black : .white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? color : Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : color.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

private struct CodexCard: View {
    let definition: DreamkeeperDefinition
    let isOwned: Bool
    let ownedCount: Int
    let maxStars: Int

    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if hasArt {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 68, height: 68)
                        .clipShape(Circle())
                } else {
                    Circle().fill(definition.rarity.gradient).frame(width: 68, height: 68)
                    Image(systemName: definition.symbol)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .overlay(
                Circle().strokeBorder(definition.rarity.gradient, lineWidth: definition.rarity.glows ? 2 : 1.2)
                    .frame(width: 68, height: 68)
            )
            .shadow(color: definition.rarity.glows ? definition.rarity.primaryColor.opacity(0.6) : .clear, radius: 8)
            .saturation(isOwned ? 1 : 0.35)
            .opacity(isOwned ? 1 : 0.7)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: definition.element.symbol)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(definition.element.color)
                    .clipShape(Circle())
                    .offset(x: 3, y: 3)
            }
            .overlay(alignment: .topTrailing) {
                if !isOwned {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Circle())
                        .offset(x: 2, y: -2)
                }
            }
            .overlay(alignment: .topLeading) {
                if definition.rarity == .exclusive {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(4)
                        .background(definition.rarity.gradient)
                        .clipShape(Circle())
                        .offset(x: -2, y: -2)
                }
            }

            // Same fix as `DreamkeeperCard`: multi-word names ("World Tree
            // Warden") don't fit this card's ~108pt column on one line even
            // scaled down 15% — two lines reads the full name instead of
            // ellipsizing it.
            Text(definition.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            if isOwned {
                StarRow(stars: maxStars)
            } else {
                Text("Not Owned")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}
