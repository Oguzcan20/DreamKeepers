import Foundation
import StoreKit

/// Result of attempting to charge real money for a `ShopItem` — kept small
/// and StoreKit-agnostic so `GameState`/UI don't need to import StoreKit or
/// reason about `VerificationResult`/`Transaction` directly.
enum PurchaseOutcome {
    case success
    case userCancelled
    case pending
    case failed
}

/// One seam for real-money purchases, same shape as `AdRewardService`:
///
///     PurchaseService
///      ├── MockPurchaseService     (used in tests/previews — always succeeds)
///      └── StoreKitPurchaseService (active — real StoreKit 2 transactions)
///
/// `GameState.purchase(_:)` remains the *grant* step (unchanged, still
/// directly unit-testable with no StoreKit involved) — this is the new
/// *charge* step that must succeed first for any item with a non-nil
/// `ShopItem.productID`. Items with a nil `productID` (currently only
/// `.goldExchange`, a virtual-currency-only trade) never go through this at
/// all and keep calling `GameState.purchase(_:)` directly.
protocol PurchaseService {
    @MainActor
    func purchase(_ item: ShopItem) async -> PurchaseOutcome
}

/// Always succeeds instantly — used by tests, SwiftUI previews, and anywhere
/// else a real StoreKit round-trip would just add noise.
struct MockPurchaseService: PurchaseService {
    @MainActor
    func purchase(_ item: ShopItem) async -> PurchaseOutcome {
        .success
    }
}

/// Real StoreKit 2 purchase flow. Requires the matching product identifiers
/// (see `ShopItem.productID` / `ShopCatalog`) to exist as In-App Purchases in
/// App Store Connect before a purchase can resolve there — until those are
/// created, `Product.products(for:)` returns no match and every purchase
/// reports `.failed`, same as a no-fill ad. For local testing before App
/// Store Connect products exist, attach `Products.storekit` (repo root) as
/// the active scheme's StoreKit Configuration in Xcode (Product ▸ Scheme ▸
/// Edit Scheme ▸ Run ▸ Options ▸ StoreKit Configuration), which serves the
/// same product IDs entirely locally.
///
/// `@MainActor`-isolated so the `Transaction.updates` listener spawned in
/// `init` can safely capture `self` inside its `Task` — Swift infers a
/// `Task { }` literal's isolation from its enclosing context, so an
/// `@MainActor` class keeps that task on the main actor without needing
/// `self` to be `Sendable`.
@MainActor
final class StoreKitPurchaseService: PurchaseService {
    private var productCache: [String: Product] = [:]
    // `nonisolated(unsafe)`: assigned once from the `nonisolated init` below
    // (before any other reference to `self` can exist) and only ever read
    // again from `deinit` (always nonisolated, but exempt from isolation
    // checking for a global-actor class's own stored properties) — never
    // touched concurrently, so opting out of actor-isolation checking here
    // is safe.
    private nonisolated(unsafe) var updatesTask: Task<Void, Never>?

    /// Fires for a verified transaction the app didn't itself initiate this
    /// launch — a restored purchase, or one approved via Ask to Buy after
    /// the original `purchase(_:)` call already returned. Apple requires
    /// listening for these (`Transaction.updates`) regardless of whether the
    /// app also drives purchases interactively. Wire this to grant the
    /// matching `ShopItem` via `GameState`, keyed by product ID.
    ///
    /// `nonisolated(unsafe)`: `GameState.init` (nonisolated, and — being a
    /// plain, non-`Sendable` class — unable to safely hop to `@MainActor`
    /// just to set a closure) assigns this exactly once, synchronously,
    /// before returning; every read happens later from `handle(_:)`, which
    /// only ever runs on the main actor. No concurrent access is possible.
    nonisolated(unsafe) var onExternalPurchase: ((_ productID: String) -> Void)?

    // `nonisolated` so `GameState.init(...)` — itself not `@MainActor` — can
    // use `StoreKitPurchaseService()` as a plain default parameter value
    // without an isolation mismatch. The spawned `Task` is explicitly
    // annotated `@MainActor` (rather than relying on inference from this
    // now-nonisolated init) so it still lands on the main actor, keeping the
    // `self` capture safe per the class-level doc comment above.
    nonisolated init() {
        updatesTask = Task { @MainActor [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func purchase(_ item: ShopItem) async -> PurchaseOutcome {
        guard let productID = item.productID else { return .failed }
        do {
            let product = try await resolveProduct(productID)
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return .failed }
                await transaction.finish()
                return .success
            case .userCancelled:
                return .userCancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    private func resolveProduct(_ productID: String) async throws -> Product {
        if let cached = productCache[productID] { return cached }
        let products = try await Product.products(for: [productID])
        guard let product = products.first else {
            throw ProductLookupError.notFound
        }
        productCache[productID] = product
        return product
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else { return }
        onExternalPurchase?(transaction.productID)
        await transaction.finish()
    }

    private enum ProductLookupError: Error {
        case notFound
    }
}
