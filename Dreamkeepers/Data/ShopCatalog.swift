import Foundation

enum ShopCatalog {
    static let starterPackID = "starter_pack"

    /// App Store Connect product identifiers all share this prefix, matching
    /// the app's own bundle ID convention.
    private static let productIDPrefix = "com.dreamhaven.dreamkeepers"

    static let gemPacks: [ShopItem] = [
        ShopItem(id: "gems_small", kind: .gemPack, name: "Handful of Gems",
                  description: "A small top-up.", priceLabel: "$0.99", icon: "sparkles",
                  gemCost: 0, goldGranted: 0, gemsGranted: 60, productID: "\(productIDPrefix).gems_small"),
        ShopItem(id: "gems_medium", kind: .gemPack, name: "Pouch of Gems",
                  description: "Good value for regular summoning.", priceLabel: "$4.99", icon: "sparkles",
                  gemCost: 0, goldGranted: 0, gemsGranted: 340, productID: "\(productIDPrefix).gems_medium"),
        ShopItem(id: "gems_large", kind: .gemPack, name: "Chest of Gems",
                  description: "Best value per gem.", priceLabel: "$9.99", icon: "sparkles",
                  gemCost: 0, goldGranted: 0, gemsGranted: 720, productID: "\(productIDPrefix).gems_large"),
        ShopItem(id: "gems_mega", kind: .gemPack, name: "Vault of Gems",
                  description: "For serious Dream Haven builders.", priceLabel: "$19.99", icon: "sparkles",
                  gemCost: 0, goldGranted: 0, gemsGranted: 1_600, productID: "\(productIDPrefix).gems_mega")
    ]

    static let goldExchanges: [ShopItem] = [
        ShopItem(id: "gold_small", kind: .goldExchange, name: "Gold Pouch",
                  description: "Exchange gems for gold.", priceLabel: "20 Gems", icon: "circle.hexagongrid.fill",
                  gemCost: 20, goldGranted: 200, gemsGranted: 0),
        ShopItem(id: "gold_large", kind: .goldExchange, name: "Gold Chest",
                  description: "Better exchange rate.", priceLabel: "80 Gems", icon: "circle.hexagongrid.fill",
                  gemCost: 80, goldGranted: 1_000, gemsGranted: 0)
    ]

    static let starterPack = ShopItem(
        id: starterPackID, kind: .starterPack, name: "Dreamkeeper Starter Pack",
        description: "One-time bonus for new Dream Haven builders: gold and gems to get your roster going.",
        priceLabel: "$2.99", icon: "gift.fill",
        gemCost: 0, goldGranted: 500, gemsGranted: 150, productID: "\(productIDPrefix).\(starterPackID)"
    )

    static let vipPassID = "vip_pass"

    static let vipPass = ShopItem(
        id: vipPassID, kind: .vip, name: "VIP Pass",
        description: "Removes rewarded-ad prompts for good — a permanent, one-time thank-you for supporting Dream Haven.",
        priceLabel: "$4.99", icon: "crown.fill",
        gemCost: 0, goldGranted: 0, gemsGranted: 0, productID: "\(productIDPrefix).\(vipPassID)"
    )

    /// Real-money-only Arena Tower ticket top-ups — never purchasable with
    /// gold or gems, by design (see `ShopItemKind.arenaTicketPack`). Granted
    /// tickets stack on top of the free daily allotment via
    /// `GameSave.arenaBonusTickets` and never expire.
    static let arenaTicketPacks: [ShopItem] = [
        ShopItem(id: "arena_tickets_small", kind: .arenaTicketPack, name: "Trial Ticket Pack",
                  description: "5 extra Endless Trial attempts, on top of your free daily tickets.",
                  priceLabel: "$1.99", icon: "ticket.fill",
                  gemCost: 0, goldGranted: 0, gemsGranted: 0, ticketsGranted: 5,
                  productID: "\(productIDPrefix).arena_tickets_small"),
        ShopItem(id: "arena_tickets_large", kind: .arenaTicketPack, name: "Trial Ticket Bundle",
                  description: "15 extra Endless Trial attempts — better value for a serious climb.",
                  priceLabel: "$4.99", icon: "ticket.fill",
                  gemCost: 0, goldGranted: 0, gemsGranted: 0, ticketsGranted: 15,
                  productID: "\(productIDPrefix).arena_tickets_large")
    ]

    /// Igo and Ames — the only two humans who ever stayed in Dream Haven.
    /// Each is its own one-time purchase (not bundled) that grants a
    /// max-level, max-star copy directly, the shop half of their dual
    /// acquisition path alongside the Summoning Shrine (see `TwinBond`).
    static let exclusiveCharacters: [ShopItem] = [
        ShopItem(id: "exclusive_igo", kind: .exclusiveCharacter, name: "Igo",
                  description: "The tide's own guardian — permanently joins your roster at max level and max stars.",
                  priceLabel: "$99.99", icon: "shield.righthalf.filled",
                  gemCost: 0, goldGranted: 0, gemsGranted: 0, grantsDefinitionID: "igo",
                  productID: "\(productIDPrefix).exclusive_igo"),
        ShopItem(id: "exclusive_ames", kind: .exclusiveCharacter, name: "Ames",
                  description: "Ember given human form — permanently joins your roster at max level and max stars.",
                  priceLabel: "$99.99", icon: "flame.fill",
                  gemCost: 0, goldGranted: 0, gemsGranted: 0, grantsDefinitionID: "ames",
                  productID: "\(productIDPrefix).exclusive_ames")
    ]

    /// Every item that carries a real-money `productID`, across all
    /// sections — used to resolve `StoreKitPurchaseService.onExternalPurchase`
    /// (a restored or Ask-to-Buy-approved transaction) back to the `ShopItem`
    /// it should grant. `.goldExchange` items are deliberately excluded —
    /// they never have a `productID` and are never charged for.
    static var allRealMoneyItems: [ShopItem] {
        gemPacks + arenaTicketPacks + exclusiveCharacters + [starterPack, vipPass]
    }
}
