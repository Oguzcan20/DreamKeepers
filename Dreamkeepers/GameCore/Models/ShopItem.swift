import Foundation

enum ShopItemKind {
    /// Real-money purchase, gated behind a real StoreKit 2 transaction via
    /// `GameState.purchaseWithRealMoney(_:)` (see `ShopItem.productID` /
    /// `PurchaseService`) — `GameState.purchase(_:)` itself only grants,
    /// never charges, which is why it stays directly unit-testable.
    case gemPack
    /// In-game soft-currency exchange: spend gems, receive gold. No real
    /// money involved, always available.
    case goldExchange
    /// One-time bonus offer, real-money priced like a gem pack but claimable
    /// only once per account.
    case starterPack
    /// One-time real-money purchase, same placeholder pattern as `gemPack`.
    /// Sets `GameSave.isVIP` instead of granting currency — permanently
    /// removes the rewarded-ad prompt (see `GameState.watchRewardedAd`).
    case vip
    /// Real-money purchase, same placeholder pattern as `gemPack`. Grants
    /// `ticketsGranted` Arena Tower tickets to `GameSave.arenaBonusTickets`.
    /// Deliberately the ONLY way to buy Arena tickets — there is no gold or
    /// gem price for them anywhere in the catalog, by design.
    case arenaTicketPack
    /// One-time real-money purchase, same placeholder pattern as `gemPack`.
    /// Grants the roster a max-level, max-star copy of `grantsDefinitionID`
    /// — the shop half of Igo/Ames' dual acquisition path, see `TwinBond`.
    case exclusiveCharacter
}

struct ShopItem: Identifiable {
    var id: String
    var kind: ShopItemKind
    var name: String
    var description: String
    var priceLabel: String
    var icon: String
    var gemCost: Int
    var goldGranted: Int
    var gemsGranted: Int
    var ticketsGranted: Int = 0
    /// `.exclusiveCharacter` only — the `DreamkeeperDefinition.id` this
    /// purchase grants.
    var grantsDefinitionID: String? = nil
    /// App Store Connect / StoreKit product identifier for real-money items
    /// (every kind except `.goldExchange`, a virtual-currency-only trade).
    /// `nil` means "never routes through `PurchaseService`" — `.goldExchange`
    /// is the only kind that should ever leave this nil.
    var productID: String? = nil
}
