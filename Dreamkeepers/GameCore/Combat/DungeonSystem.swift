import Foundation

/// The three Dungeons ("Schlünde") — ported from the Flutter/Android build to
/// bring iOS to parity. `storageKey` is the stable, never-localized string
/// used by `GameSave.clearedDungeonIDs`.
enum DungeonID: String, CaseIterable, Identifiable {
    case whisperwood
    case gloomvault
    case starspire

    var id: String { rawValue }
    var storageKey: String { rawValue }
}

/// Static per-dungeon configuration and combat/reward math. Each dungeon is
/// a single `waveCount`-wave run fought back-to-back in one `BattleView` with
/// no healing between waves (two regular waves, then a boss). Entry costs one
/// Dungeon Key (`maxKeysPerDay` per day, refilled at local midnight). The
/// first clear pays a big fixed reward — gold, Dream Gems, and a guaranteed
/// high-rarity item; later clears pay a smaller repeatable farm reward.
enum DungeonSystem {
    /// Dungeon Keys handed out per calendar day.
    static let maxKeysPerDay = 3

    /// Waves per run — two regular encounters and a boss finale.
    static let waveCount = 3

    static let all: [DungeonID] = DungeonID.allCases

    static func displayName(_ id: DungeonID) -> String {
        switch id {
        case .whisperwood: return "Whisperwood"
        case .gloomvault: return "Gloomvault"
        case .starspire: return "Starspire"
        }
    }

    static func blurb(_ id: DungeonID) -> String {
        switch id {
        case .whisperwood: return "A hushed grove where the roots themselves seem to listen back."
        case .gloomvault: return "A sealed crypt beneath the moon, guarded by what it never let leave."
        case .starspire: return "A tower that pierces the sky — its peak answers to nothing but starlight."
        }
    }

    static func icon(_ id: DungeonID) -> String {
        switch id {
        case .whisperwood: return "leaf.fill"
        case .gloomvault: return "moon.stars.fill"
        case .starspire: return "sparkles"
        }
    }

    /// Rough team level a run is tuned for — shown in the hub as guidance.
    static func recommendedLevel(_ id: DungeonID) -> Int {
        switch id {
        case .whisperwood: return 12
        case .gloomvault: return 28
        case .starspire: return 45
        }
    }

    /// Overall enemy-strength multiplier over a fresh Dreamkeeper's own stats
    /// — the three dungeons form a clear low/mid/high ladder.
    private static func powerScale(_ id: DungeonID) -> Double {
        switch id {
        case .whisperwood: return 2.0
        case .gloomvault: return 5.0
        case .starspire: return 10.0
        }
    }

    private static func theme(_ id: DungeonID) -> Element {
        switch id {
        case .whisperwood: return .bloom
        case .gloomvault: return .lunar
        case .starspire: return .astral
        }
    }

    private static func bossMechanic(_ id: DungeonID) -> BossMechanic {
        switch id {
        case .whisperwood: return .regenShield
        case .gloomvault: return .enrage
        case .starspire: return .sovereign
        }
    }

    /// The `waveCount` enemies of a run, in order — index 0 is fought first,
    /// the last is the boss. Built from flat base stats × `powerScale` the
    /// same way `ArenaSystem.makeCombatant` synthesizes its rival, so no
    /// catalog lookup is needed.
    static func waves(_ id: DungeonID) -> [Combatant] {
        let scale = powerScale(id)
        let element = theme(id)
        var result: [Combatant] = []
        for wave in 0..<waveCount {
            let isBoss = wave == waveCount - 1
            // Each successive wave is a little tougher; the boss then jumps again.
            let waveScale = scale * (1.0 + Double(wave) * 0.15) * (isBoss ? 1.6 : 1.0)
            result.append(Combatant(
                id: UUID(),
                name: isBoss ? "\(displayName(id)) Warden" : "Wave \(wave + 1) Pack",
                element: element,
                role: isBoss ? .tank : .damage,
                isPlayer: false,
                isBoss: isBoss,
                maxHP: (64 * waveScale).rounded(),
                currentHP: (64 * waveScale).rounded(),
                attack: (12 * waveScale).rounded(),
                defense: (5 * waveScale).rounded(),
                speed: (44 + Double(wave) * 3).rounded(),
                ultimate: nil,
                symbol: isBoss ? "crown.fill" : element.symbol,
                mechanic: isBoss ? bossMechanic(id) : nil
            ))
        }
        return result
    }

    // MARK: - Rewards

    /// Campaign-stage-equivalent used to size an item drop's stat magnitude
    /// (see `EquipmentFactory.item`).
    private static func lootStageValue(_ id: DungeonID) -> Int {
        switch id {
        case .whisperwood: return 20
        case .gloomvault: return 45
        case .starspire: return 80
        }
    }

    static func firstClearGold(_ id: DungeonID) -> Int {
        switch id {
        case .whisperwood: return 400
        case .gloomvault: return 1200
        case .starspire: return 3000
        }
    }

    static func firstClearGems(_ id: DungeonID) -> Int {
        switch id {
        case .whisperwood: return 15
        case .gloomvault: return 30
        case .starspire: return 60
        }
    }

    /// Guaranteed rarity of the first-clear item reward.
    static func firstClearRarity(_ id: DungeonID) -> Rarity {
        switch id {
        case .whisperwood: return .epic
        case .gloomvault: return .legendary
        case .starspire: return .legendary
        }
    }

    /// Repeatable farm gold for an already-cleared dungeon — a fraction of
    /// the one-off first-clear payout.
    static func repeatGold(_ id: DungeonID) -> Int {
        Int((Double(firstClearGold(id)) * 0.4).rounded())
    }

    /// Campaign-stage-equivalent for sizing any item drop's stat magnitude.
    static func lootStage(_ id: DungeonID) -> Int { lootStageValue(id) }
}
