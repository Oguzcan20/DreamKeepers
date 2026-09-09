import Foundation

/// A small, deterministic pseudo-random source (splitmix64-style) so
/// `ArenaSystem.opponentForFloor` produces the *same* rival for a given
/// floor every time it's called — the Arena hub re-reads
/// `GameState.arenaOpponent` on every body evaluation, and a retry after a
/// loss should face the exact same rival, not a reshuffled one.
/// `Int.random(using:)`/`Array.randomElement(using:)` both work against any
/// `RandomNumberGenerator`, so this drops straight in.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed &+ 0x9E3779B97F4A7C15
    }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Arena Tower tiers — purely a labeled banding of `GameSave.arenaFloor`
/// for the hub/result UI, same idea as `Rarity` bands a raw drop-weight.
enum ArenaTier: Int, CaseIterable, Comparable {
    case bronze, silver, gold, platinum, diamond

    static func < (lhs: ArenaTier, rhs: ArenaTier) -> Bool { lhs.rawValue < rhs.rawValue }

    static func tier(for floor: Int) -> ArenaTier {
        switch floor {
        case ..<21: return .bronze
        case 21..<41: return .silver
        case 41..<61: return .gold
        case 61..<81: return .platinum
        default: return .diamond
        }
    }

    var displayName: String {
        switch self {
        case .bronze: return "Bronze"
        case .silver: return "Silver"
        case .gold: return "Gold"
        case .platinum: return "Platinum"
        case .diamond: return "Diamond"
        }
    }

    var symbol: String {
        switch self {
        case .bronze: return "shield.fill"
        case .silver: return "shield.lefthalf.filled"
        case .gold: return "shield.checkered"
        case .platinum: return "star.circle.fill"
        case .diamond: return "crown.fill"
        }
    }

    /// Inclusive floor range this tier spans — five equal 20-floor bands
    /// covering `ArenaSystem.maxFloor` exactly (kept in sync with
    /// `tier(for:)`'s thresholds above), used by the Arena Tower UI to group
    /// floors into visually distinct tower "zones" without hardcoding the
    /// band width a second time.
    var floorRange: ClosedRange<Int> {
        switch self {
        case .bronze: return 1...20
        case .silver: return 21...40
        case .gold: return 41...60
        case .platinum: return 61...80
        case .diamond: return 81...ArenaSystem.maxFloor
        }
    }

    /// Flavor name for this tier's section of the Arena Tower structure —
    /// distinct from `displayName` (the compact badge elsewhere), used only
    /// by the tower-zone banner between floor blocks.
    var zoneName: String {
        switch self {
        case .bronze: return "Bronze Halls"
        case .silver: return "Silver Vault"
        case .gold: return "Gold Sanctum"
        case .platinum: return "Platinum Ascent"
        case .diamond: return "Diamond Summit"
        }
    }
}

/// The AI-controlled rival guarding one Arena Tower floor. There is no real
/// backend or matchmaking (`LeaderboardService` only ever submits a
/// campaign-progress leaderboard score) — so "PvP" here means fighting a
/// freshly-synthesized, fair stand-in for another player's team, not a live
/// opponent. Freshly generated, never persisted; see
/// `ArenaSystem.opponentForFloor`. `floor` alone identifies it, since the
/// same floor always deterministically generates the same rival.
struct ArenaOpponent: Equatable {
    let floor: Int
    let name: String
    let definitionID: String
    let level: Int
}

/// Opponent generation, floor-scaling math, and the single-rival combat
/// stand-in the Arena Tower fights against. Deliberately reuses the existing
/// single-enemy `BattleEngine`/`BattleView` pipeline unchanged — a floor's
/// rival "team" is represented as one elevated-stat `Combatant` (a rival
/// captain), the same way a stage boss already stands in for its whole
/// encounter, rather than requiring a second multi-enemy battle UI.
enum ArenaSystem {
    /// Highest climbable floor — reaching `maxFloor + 1` means the tower is
    /// fully cleared (see `GameState.isArenaTowerCleared`).
    static let maxFloor = 100

    /// Daily attempts, refilled at local midnight — deliberately its own
    /// economy instead of spending shared `energy`, so climbing the tower
    /// never competes with Campaign stages for the same stamina bar.
    static let maxTicketsPerDay = 5

    /// Every Nth floor guarantees a legendary+ bonus reward on top of the
    /// normal floor payout — see `GameState.applyArenaBattleResult`.
    static let milestoneInterval = 25

    static func isMilestoneFloor(_ floor: Int) -> Bool {
        floor % milestoneInterval == 0
    }

    private static let rivalNames = [
        "Team Nachtklinge", "Team Sternenschatten", "Team Glutmähne",
        "Team Flussgeist", "Team Wurzelbund", "Team Mondsichel",
        "Team Aschekrone", "Team Tiefenruf", "Team Lichtbrecher", "Team Sturmauge"
    ]

    /// The rival guarding `floor` — deterministic per floor (see
    /// `SeededGenerator`'s doc comment for why), so it holds steady across
    /// every read and stays the same on a retry after a loss.
    static func opponentForFloor(_ floor: Int, catalog: DreamkeeperCatalog) -> ArenaOpponent {
        let pool = catalog.definitions
        var rng = SeededGenerator(seed: UInt64(floor))
        let def = pool.randomElement(using: &rng) ?? pool[0]
        let name = rivalNames.randomElement(using: &rng) ?? "Team Rivale"
        let level = min(LevelSystem.maxLevel, 1 + floor / 2)
        return ArenaOpponent(floor: floor, name: name, definitionID: def.id, level: level)
    }

    /// Per-floor stat multiplier — floor 1 opens at roughly a fresh
    /// Dreamkeeper's own strength and climbs steadily past the campaign's
    /// own hardest boss (~39.6x at stage 50) well before floor 100 (~53x),
    /// so the tower stays a genuine long-term goal even for a maxed-out
    /// roster (`LevelSystem.maxLevel`/`StarFusionSystem.maxStars` would
    /// otherwise flatten out a 100-floor curve).
    static func scale(forFloor floor: Int) -> Double {
        1.0 + Double(floor - 1) * 0.528
    }

    /// Synthesizes the rival's combat stand-in directly from base stats ×
    /// `scale(forFloor:)` — deliberately bypasses `DreamkeeperInstance.currentStats`
    /// (and its player-progression caps) the same way `EnemyFactory.enemy(forStage:)`
    /// does for campaign enemies, so difficulty has real room to climb across
    /// all 100 floors.
    static func makeCombatant(for opponent: ArenaOpponent, in catalog: DreamkeeperCatalog) -> Combatant? {
        guard let def = catalog.definition(for: opponent.definitionID) else { return nil }
        let totalScale = scale(forFloor: opponent.floor)
        return Combatant(
            id: UUID(), name: opponent.name, element: def.element, role: def.role,
            isPlayer: false, isBoss: false,
            maxHP: (70 * totalScale).rounded(), currentHP: (70 * totalScale).rounded(),
            attack: (13 * totalScale).rounded(), defense: (6 * totalScale).rounded(),
            speed: (40 + Double(opponent.floor) * 0.6).rounded(),
            ultimate: def.ultimate, symbol: def.symbol,
            // Show the real Dreamkeeper portrait this rival's stats/kit are
            // borrowed from, instead of the flavor team name never matching
            // any imageset — see `Combatant.portraitOverrideName`.
            portraitOverrideName: def.name
        )
    }

    /// Gold payout for clearing a floor — climbs steadily so a deliberate
    /// grind up the tower stays worth it the whole way (floor 100 pays
    /// ~940, on par with the campaign's own stage-50 boss).
    static func goldReward(floor: Int) -> Int {
        40 + floor * 9
    }

    static func firstClearGoldReward(floor: Int) -> Int { goldReward(floor: floor) }

    /// Rarity floor a floor's FIRST-clear equipment reward is guaranteed to
    /// hit — rises with `ArenaTier`, and any milestone floor (every
    /// `milestoneInterval`th) is bumped straight to Legendary regardless of
    /// tier, so those floors stay the standout reward promised at a glance
    /// in the floor list.
    static func firstClearRarity(forFloor floor: Int) -> Rarity {
        if isMilestoneFloor(floor) { return .legendary }
        switch ArenaTier.tier(for: floor) {
        case .bronze: return .common
        case .silver: return .uncommon
        case .gold: return .rare
        case .platinum: return .epic
        case .diamond: return .legendary
        }
    }

    /// The exact item a floor's first clear grants — seeded by the floor
    /// number alone (offset so it never lands on the same "random" slot the
    /// opponent roll picked), so it's fully deterministic and can be shown
    /// in the floor-list UI before the fight, not just after.
    static func firstClearEquipment(forFloor floor: Int) -> EquipmentItem {
        var rng = SeededGenerator(seed: UInt64(floor) &+ 0x1000003)
        let slot = EquipmentSlot.allCases.randomElement(using: &rng) ?? .weapon
        return EquipmentFactory.item(forStage: floor, rarity: firstClearRarity(forFloor: floor), slot: slot)
    }

    /// Smaller, RNG-based reward for replaying an already-cleared floor —
    /// the repeatable farm loop players use once they know which floor
    /// drops the gear they're after. Deliberately not previewable/fixed
    /// like the first-clear reward, since it's meant to be replayed many
    /// times rather than shown once.
    static func standardGoldReward(floor: Int) -> Int {
        15 + floor * 2
    }

    static func standardEquipmentDrop(forFloor floor: Int) -> EquipmentItem? {
        guard EquipmentFactory.shouldDrop(isBoss: false) else { return nil }
        return EquipmentFactory.randomItem(forStage: floor, isBoss: false)
    }
}
