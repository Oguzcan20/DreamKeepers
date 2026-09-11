import Foundation

/// Permanent account-wide upgrade tracks Rebirth unlocks. Each track has its
/// own max rank, per-rank effect size, and linear cost-per-rank — direct port
/// of the Flutter/Android `SoulUpgrade` enum, kept in lockstep with it.
enum SoulUpgrade: String, CaseIterable, Identifiable {
    case goldFind
    case expBoost
    case damage
    case offlineRewards

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .goldFind: return "Gold Find"
        case .expBoost: return "EXP Boost"
        case .damage: return "Damage"
        case .offlineRewards: return "Offline Rewards"
        }
    }

    var detail: String {
        switch self {
        case .goldFind: return "Permanently increases all Gold earned."
        case .expBoost: return "Permanently increases all EXP earned."
        case .damage: return "Permanently increases damage dealt in battle."
        case .offlineRewards: return "Permanently increases offline Gold Fountain and Training Garden rewards."
        }
    }

    var icon: String {
        switch self {
        case .goldFind: return "circle.hexagongrid.fill"
        case .expBoost: return "star.fill"
        case .damage: return "bolt.fill"
        case .offlineRewards: return "moon.zzz.fill"
        }
    }
}

/// Prestige / Rebirth ("Wiedergeburt / Seelenpunkte") — resets the Endless
/// Trial tower back to floor 1 in exchange for Soul Points banked from the
/// floor reached, spendable on permanent, account-wide `SoulUpgrade` bonuses.
/// A Flutter-originated feature ported here to bring iOS to parity; pure math
/// only — `GameState` owns all persistence and mutation.
enum RebirthSystem {
    /// Endless Trial floor a player must have reached before Rebirth unlocks.
    static let rebirthFloorRequirement = 50

    /// One Soul Point per five floors climbed (floor 1 banks nothing).
    static func soulPointsForFloor(_ arenaFloor: Int) -> Int {
        max(0, (arenaFloor - 1) / 5)
    }

    static func maxRank(_ upgrade: SoulUpgrade) -> Int {
        switch upgrade {
        case .goldFind, .expBoost, .damage: return 10
        case .offlineRewards: return 5
        }
    }

    static func effectPerRank(_ upgrade: SoulUpgrade) -> Double {
        switch upgrade {
        case .goldFind, .expBoost: return 0.04
        case .damage: return 0.02
        case .offlineRewards: return 0.10
        }
    }

    private static func baseCost(_ upgrade: SoulUpgrade) -> Int {
        switch upgrade {
        case .goldFind, .expBoost: return 2
        case .damage, .offlineRewards: return 3
        }
    }

    /// Linear escalation — the cost to buy a given rank (not cumulative).
    static func costForRank(_ upgrade: SoulUpgrade, _ rank: Int) -> Int {
        baseCost(upgrade) * rank
    }

    /// `1.0` at rank 0 (no-op), rising by `effectPerRank` per rank, clamped
    /// to the track's max rank.
    static func effectMultiplier(_ upgrade: SoulUpgrade, _ rank: Int) -> Double {
        let clamped = min(max(rank, 0), maxRank(upgrade))
        return 1.0 + Double(clamped) * effectPerRank(upgrade)
    }
}
