import Foundation

/// A season's worth of tiered rewards along two tracks (spec: "Kostenlose
/// und Premium-Spur"). Pure, testable math — GameState owns persistence,
/// BattlePassView owns presentation.
enum BattlePassSystem {
    static let tierCount = 20
    static let xpPerTier = 120

    /// Flat Battle Pass XP granted per battle win, independent of stage —
    /// keeps season pacing predictable regardless of which stage is farmed.
    static func xpGained(isBoss: Bool) -> Int {
        isBoss ? 40 : 15
    }

    /// The highest tier unlocked by `xp`, clamped to `tierCount`. Tier 0
    /// means no tier has been reached yet.
    static func tier(forXP xp: Int) -> Int {
        min(tierCount, xp / xpPerTier)
    }

    /// XP progress within the current (not yet completed) tier, for a
    /// progress bar toward the next one.
    static func progressWithinTier(forXP xp: Int) -> (current: Int, needed: Int) {
        guard tier(forXP: xp) < tierCount else { return (xpPerTier, xpPerTier) }
        return (xp % xpPerTier, xpPerTier)
    }

    struct Reward: Equatable {
        var gold: Int
        var gems: Int
        var tickets: Int = 0
    }

    /// Free track: modest, steadily-growing gold. No gems on the free track
    /// — Dream Gems stay a premium-track/summon incentive (spec: not P2W,
    /// but premium should still feel meaningfully better). A small Arena
    /// ticket bonus every 10th tier gives free-track players a taste of the
    /// Tower's real-money-only ticket economy without it being the main draw.
    static func freeReward(forTier tier: Int) -> Reward {
        Reward(gold: 40 * tier, gems: 0, tickets: tier % 10 == 0 ? 3 : 0)
    }

    /// Premium track: gold plus gems every tier, with a bonus gem spike and
    /// an Arena ticket grant every 5th tier as a season milestone — the
    /// Battle Pass' only non-real-money source of Arena tickets at real
    /// scale (see `ShopItemKind.arenaTicketPack` for the paid path).
    static func premiumReward(forTier tier: Int) -> Reward {
        let milestoneBonus = tier % 5 == 0 ? 30 : 0
        let tickets = tier % 5 == 0 ? 5 : 0
        return Reward(gold: 25 * tier, gems: 10 + milestoneBonus, tickets: tickets)
    }
}
