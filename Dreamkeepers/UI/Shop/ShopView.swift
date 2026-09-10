import SwiftUI

struct ShopView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var justPurchasedID: String?
    @State private var appeared = false

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.gold, bottomTint: Theme.violet)

            VStack(spacing: 0) {
                header

                ScrollView {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 14) {
                            if !gameState.isPurchased(ShopCatalog.starterPack) {
                                starterPackCard
                            }
                            if !gameState.isVIP {
                                vipPassCard
                            }
                            exclusiveCharactersSection
                            arenaTicketSection
                            goldExchangeSection
                            Spacer(minLength: 0)
                        }
                        .frame(width: 300)

                        gemPacksSection
                            .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(20)
                    .frame(minHeight: 340)
                }
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
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
                Image(systemName: ShopCatalog.starterPack.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.gold)
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
                Image(systemName: ShopCatalog.vipPass.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.violet)
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

    /// Igo and Ames, the two Exclusive-rarity Dreamwalkers — the shop half
    /// of their dual acquisition path alongside the Summoning Shrine (see
    /// `TwinBond`). Each is its own one-time card, following the same
    /// `starterPackCard`/`vipPassCard` claimed-once pattern; a card
    /// disappears once that character is owned.
    @ViewBuilder
    private var exclusiveCharactersSection: some View {
        ForEach(ShopCatalog.exclusiveCharacters) { item in
            if gameState.canPurchase(item) {
                exclusiveCharacterCard(for: item)
            }
        }
    }

    private func exclusiveCharacterCard(for item: ShopItem) -> some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.gold)
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

    private var gemPacksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dream Gems")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ShopCatalog.gemPacks) { item in
                    GemPackCard(item: item, badge: badge(for: item), justPurchased: justPurchasedID == item.id) {
                        buy(item)
                    }
                }
            }
        }
    }

    /// Arena Tower tickets, real-money only by design — see
    /// `ShopItemKind.arenaTicketPack`. Unlike `goldExchangeSection` there is
    /// deliberately no in-game currency price shown or accepted here.
    private var arenaTicketSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trial Tickets")
                .font(.headline)
                .foregroundStyle(.white)

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
            Text("Gold Exchange")
                .font(.headline)
                .foregroundStyle(.white)

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

private struct GemPackCard: View {
    let item: ShopItem
    let badge: (LocalizedStringKey, Color)?
    let justPurchased: Bool
    var onBuy: () -> Void

    var body: some View {
        GlassCard {
            VStack(spacing: 8) {
                Image(systemName: item.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.violet)
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
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.softBlue)
                    .frame(width: 28)
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
                Image(systemName: item.icon)
                    .font(.title3)
                    .foregroundStyle(Theme.gold)
                    .frame(width: 28)
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
