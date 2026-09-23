import SwiftUI

private enum ShopTab {
    case offers, gems, extras
}

struct ShopView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var justPurchasedID: String?
    @State private var appeared = false
    @State private var tab: ShopTab

    init(gameState: GameState, navigate: @escaping (AppRoute) -> Void) {
        self.gameState = gameState
        self.navigate = navigate
        // Opens on whichever tab actually has something new for a returning
        // player — once every one-time offer is claimed there's nothing left
        // in Offers, so Gems is the more useful start.
        let hasOffers = !gameState.isPurchased(ShopCatalog.starterPack) || !gameState.isVIP
            || ShopCatalog.exclusiveCharacters.contains { gameState.canPurchase($0) }
        _tab = State(initialValue: hasOffers ? .offers : .gems)
    }

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.gold, bottomTint: Theme.violet)

            VStack(spacing: 0) {
                header
                tabBar
                    .padding(.top, 10)

                Group {
                    switch tab {
                    case .offers: offersTab
                    case .gems: gemsTab
                    case .extras: extrasTab
                    }
                }
                .padding(.top, 6)
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
    }

    /// Whether the Offers tab has anything to show — hidden dot on its tab
    /// once every one-time offer in that block is already claimed.
    private var hasSpecialOffers: Bool {
        !gameState.isPurchased(ShopCatalog.starterPack) || !gameState.isVIP
            || ShopCatalog.exclusiveCharacters.contains { gameState.canPurchase($0) }
    }

    /// Three-way segmented control, same visual pattern as `InventoryView`'s
    /// Dreamkeepers/Items picker — replaces the old single tall two-column
    /// `ScrollView`, whose left column (Special Offers + both Exclusive
    /// characters + Arena Tickets + Gold Exchange) ran far taller than the
    /// Gem Packs column beside it, forcing much more scrolling than any one
    /// purchase needed.
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(.offers, "Offers", showDot: hasSpecialOffers)
            tabButton(.gems, "Gems")
            tabButton(.extras, "Tickets & Gold")
        }
        .padding(3)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func tabButton(_ value: ShopTab, _ title: LocalizedStringKey, showDot: Bool = false) -> some View {
        let selected = tab == value
        return Button {
            tab = value
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(selected ? 1 : 0.6))
                if showDot {
                    Circle().fill(Theme.gold).frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Color.white.opacity(0.16) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var offersTab: some View {
        let cards: [AnyView] = {
            var result: [AnyView] = []
            if !gameState.isPurchased(ShopCatalog.starterPack) { result.append(AnyView(starterPackCard)) }
            if !gameState.isVIP { result.append(AnyView(vipPassCard)) }
            for item in ShopCatalog.exclusiveCharacters where gameState.canPurchase(item) {
                result.append(AnyView(exclusiveCharacterCard(for: item)))
            }
            return result
        }()
        return ScrollView {
            if cards.isEmpty {
                emptyState("No special offers right now — check back soon.")
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 14)], spacing: 14) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                        card
                    }
                }
                .padding(20)
            }
        }
    }

    private var gemsTab: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                ForEach(ShopCatalog.gemPacks) { item in
                    GemPackCard(item: item, badge: badge(for: item), justPurchased: justPurchasedID == item.id) {
                        buy(item)
                    }
                }
            }
            .padding(20)
        }
    }

    /// Arena Tickets and the Gold Exchange side by side — two short,
    /// independent lists that used to be stacked into one long column; as
    /// columns of a wide two-up row they each fit without scrolling.
    private var extrasTab: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 16) {
                arenaTicketSection
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.clear, .white.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 1)
                    .frame(minHeight: 140)
                goldExchangeSection
            }
            .padding(20)
        }
    }

    private func emptyState(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.top, 60)
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            Text("Shop")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                ResourcePill(systemImage: "circle.hexagongrid.fill", value: "\(gameState.save.gold)", tint: Theme.gold, accessibilityLabelText: "Gold")
                ResourcePill(systemImage: "sparkles", value: "\(gameState.save.dreamGems)", tint: Theme.violet, accessibilityLabelText: "Dream Gems")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var starterPackCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                IconBadge(systemImage: ShopCatalog.starterPack.icon, tint: Theme.gold)
                Text(LocalizedStringKey(ShopCatalog.starterPack.name))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(ShopCatalog.starterPack.description))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Label("\(ShopCatalog.starterPack.goldGranted)", systemImage: "circle.hexagongrid.fill")
                        .foregroundStyle(Theme.gold)
                    Label("\(ShopCatalog.starterPack.gemsGranted)", systemImage: "sparkles")
                        .foregroundStyle(Theme.violet)
                }
                .font(.caption.weight(.semibold))

                purchaseButton(for: ShopCatalog.starterPack, tint: Theme.gold)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.gold.opacity(0.3), radius: 14, y: 4)
    }

    private var vipPassCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                IconBadge(systemImage: ShopCatalog.vipPass.icon, tint: Theme.violet)
                Text(LocalizedStringKey(ShopCatalog.vipPass.name))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(ShopCatalog.vipPass.description))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                purchaseButton(for: ShopCatalog.vipPass, tint: Theme.violet)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.violet.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.violet.opacity(0.3), radius: 14, y: 4)
    }

    /// Locale-invariant art name for the character this item grants — never
    /// derived from `item.name`, which is localized; mirrors the `artName`
    /// convention every `DreamkeeperDefinition` art lookup elsewhere uses.
    private static let exclusiveArtNames = ["igo": "Igo", "ames": "Ames"]

    private func exclusiveCharacterCard(for item: ShopItem) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                if let artName = item.grantsDefinitionID.flatMap({ Self.exclusiveArtNames[$0] }) {
                    PortraitBadge(artName: artName, fallbackSystemImage: item.icon)
                } else {
                    IconBadge(systemImage: item.icon, tint: Theme.gold, diameter: 64, iconSize: 28)
                }
                Text(LocalizedStringKey(Rarity.exclusive.displayName))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Rarity.exclusive.gradient)
                    .clipShape(Capsule())
                Text(LocalizedStringKey(item.name))
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(item.description))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                purchaseButton(for: item, tint: Theme.gold)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Rarity.exclusive.primaryColor.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Rarity.exclusive.primaryColor.opacity(0.3), radius: 14, y: 4)
    }

    /// Arena Tower tickets, real-money only by design — see
    /// `ShopItemKind.arenaTicketPack`. Unlike `goldExchangeSection` there is
    /// deliberately no in-game currency price shown or accepted here.
    private var arenaTicketSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Trial Tickets")

            VStack(spacing: 10) {
                ForEach(ShopCatalog.arenaTicketPacks) { item in
                    TicketPackRow(item: item, justPurchased: justPurchasedID == item.id) {
                        buy(item)
                    }
                }
            }
        }
    }

    private var goldExchangeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Gold Exchange")

            VStack(spacing: 10) {
                ForEach(ShopCatalog.goldExchanges) { item in
                    ExchangeRow(item: item, canAfford: gameState.canPurchase(item)) {
                        buy(item)
                    }
                }
            }
        }
    }

    private func purchaseButton(for item: ShopItem, tint: Color) -> some View {
        let purchased = gameState.isPurchased(item)
        return Button {
            buy(item)
        } label: {
            if purchased {
                Text("Claimed")
            } else if justPurchasedID == item.id {
                Text("Purchased!")
            } else {
                Text(LocalizedStringKey(item.priceLabel))
            }
        }
        .buttonStyle(PrimaryButtonStyle(tint: tint))
        .disabled(purchased || !gameState.canPurchase(item))
    }

    /// Ribbon shown on a gem pack card, if any. Hand-picked rather than
    /// derived (e.g. from gems-per-dollar) so the two callouts stay
    /// deliberately distinct: the mid pack as the approachable default,
    /// the large pack backing up its existing "Best value per gem" copy.
    private func badge(for item: ShopItem) -> (LocalizedStringKey, Color)? {
        switch item.id {
        case "gems_medium": return ("Popular", Theme.violet)
        case "gems_large": return ("Best Value", Theme.gold)
        default: return nil
        }
    }

    private func buy(_ item: ShopItem) {
        Task {
            guard await gameState.purchaseWithRealMoney(item) else { return }
            gameState.playHaptic(.levelUp)
            justPurchasedID = item.id
            try? await Task.sleep(for: .seconds(1.2))
            if justPurchasedID == item.id { justPurchasedID = nil }
        }
    }
}

/// Icon inside a tinted, glowing circle — the badge treatment already
/// established by `ProfileView`'s level card and the achievement toast,
/// reused here so every Shop card reads as one consistent visual language
/// instead of bare floating icons.
private struct IconBadge: View {
    let systemImage: String
    let tint: Color
    var diameter: CGFloat = 56
    var iconSize: CGFloat = 22

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.2))
                .frame(width: diameter, height: diameter)
                .shadow(color: tint.opacity(0.35), radius: 12)
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

/// Circular character portrait for Igo/Ames' exclusive shop cards, falling
/// back to an `IconBadge` when the art asset isn't available — mirrors the
/// `hasArt` gating every other art lookup in the app already uses.
private struct PortraitBadge: View {
    static let diameter: CGFloat = 64

    let artName: String
    let fallbackSystemImage: String

    var body: some View {
        if DreamkeeperArt.hasArt(for: artName) {
            Image(DreamkeeperArt.assetName(for: artName))
                .resizable()
                .scaledToFill()
                .frame(width: Self.diameter, height: Self.diameter)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.gold.opacity(0.7), lineWidth: 2))
                .shadow(color: Theme.gold.opacity(0.35), radius: 14)
        } else {
            IconBadge(systemImage: fallbackSystemImage, tint: Theme.gold, diameter: Self.diameter, iconSize: Self.diameter * 0.46)
        }
    }
}

private struct GemPackCard: View {
    let item: ShopItem
    let badge: (LocalizedStringKey, Color)?
    let justPurchased: Bool
    var onBuy: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                IconBadge(systemImage: item.icon, tint: Theme.violet, diameter: 44, iconSize: 18)
                    .padding(.top, badge != nil ? 12 : 0)
                Text("\(item.gemsGranted)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(item.name))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                Button(action: onBuy) {
                    Text(LocalizedStringKey(justPurchased ? "Added!" : item.priceLabel))
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .top) {
            if let badge {
                Text(badge.0)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(badge.1)
                    .clipShape(Capsule())
                    .shadow(color: badge.1.opacity(0.5), radius: 6, y: 2)
                    .offset(y: -10)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(badge?.1.opacity(0.5) ?? .clear, lineWidth: 1.5)
        )
    }
}

private struct TicketPackRow: View {
    let item: ShopItem
    let justPurchased: Bool
    var onBuy: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                IconBadge(systemImage: item.icon, tint: Theme.softBlue, diameter: 40, iconSize: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(item.name))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("+\(item.ticketsGranted) Tickets")
                        .font(.caption)
                        .foregroundStyle(Theme.softBlue)
                }
                Spacer()
                Button(action: onBuy) {
                    Text(LocalizedStringKey(justPurchased ? "Added!" : item.priceLabel))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.softBlue.opacity(0.35))
                .clipShape(Capsule())
            }
        }
    }
}

private struct ExchangeRow: View {
    let item: ShopItem
    let canAfford: Bool
    var onBuy: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                IconBadge(systemImage: item.icon, tint: Theme.gold, diameter: 40, iconSize: 16)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(item.name))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("+\(item.goldGranted) Gold")
                        .font(.caption)
                        .foregroundStyle(Theme.gold)
                }
                Spacer()
                Button(action: onBuy) {
                    Label(LocalizedStringKey(item.priceLabel), systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.violet.opacity(0.35))
                .clipShape(Capsule())
                .disabled(!canAfford)
                .opacity(canAfford ? 1 : 0.5)
            }
        }
    }
}
