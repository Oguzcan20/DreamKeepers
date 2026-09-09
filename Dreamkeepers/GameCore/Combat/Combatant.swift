import SwiftUI

/// A world boss's signature twist — see `BattleEngine.triggerBossMechanicIfNeeded`
/// and `applyDamage` for where each one actually fires.
enum BossMechanic: Equatable {
    /// Heals for 25% max HP once, the first time HP drops to/below 50%.
    case selfHeal
    /// +50% attack once, the first time HP drops to/below 30%.
    case enrage
    /// Reduces incoming damage by 60% for its first 3 hits taken; purely
    /// data-driven via `shieldCharges`, so this case is mostly a content tag.
    case shield
    /// Resets every player unit's ultimate energy to 0 once, the first time
    /// HP drops to/below 50% (Morvane: "entzieht Dreamkeepern Energie").
    case drain
    /// Grants 3 fresh shield charges once, the first time HP drops to/below
    /// 50% — a mid-fight shield rather than one active from the start
    /// (Verdantor: "Regenerationsschild").
    case regenShield
    /// +35% attack and 3 fresh shield charges together once, the first time
    /// HP drops to/below 50% — the light/shadow turn (Noctyra: "wechselt
    /// zwischen Licht- und Schattenphase").
    case phaseShift
    /// Heals for 20% max HP, +50% attack, and 3 fresh shield charges all at
    /// once, the first time HP drops to/below 40% — the final boss's one
    /// big turn (Elyndor: "mehrere Phasen... finale Ultimate-Phase").
    case sovereign

    /// Short banner text for the mechanic-trigger flash (`MechanicEvent`) —
    /// kept on the enum so the label/icon pairing lives in one data-driven
    /// place instead of a switch buried in the view layer.
    var triggerLabel: String {
        switch self {
        case .selfHeal: return "Healed!"
        case .enrage: return "Enraged!"
        case .shield: return "Shielded!"
        case .drain: return "Drained!"
        case .regenShield: return "Shielded!"
        case .phaseShift: return "Phase Shift!"
        case .sovereign: return "Awakened!"
        }
    }

    var triggerSymbol: String {
        switch self {
        case .selfHeal: return "cross.case.fill"
        case .enrage: return "flame.fill"
        case .shield: return "shield.fill"
        case .drain: return "bolt.slash.fill"
        case .regenShield: return "shield.lefthalf.filled"
        case .phaseShift: return "circle.lefthalf.filled"
        case .sovereign: return "crown.fill"
        }
    }

    var triggerColor: Color {
        switch self {
        case .selfHeal: return .green
        case .enrage: return .red
        case .shield: return Theme.softBlue
        case .drain: return .purple
        case .regenShield: return Theme.softBlue
        case .phaseShift: return Theme.violet
        case .sovereign: return Theme.gold
        }
    }
}

/// One participant inside a live battle — player Dreamkeeper or enemy.
/// Distinct from `DreamkeeperInstance`: this is transient combat state, not
/// something that gets saved.
struct Combatant: Identifiable, Equatable {
    let id: UUID
    let name: String
    let element: Element
    let role: Role
    let isPlayer: Bool
    let isBoss: Bool
    /// Species id for player units (`DreamkeeperInstance.definitionID`), used
    /// only by the UI to render the Zwillingsbund badge — `BattleEngine`
    /// itself never dispatches on this, only on `role`/passive data.
    var definitionID: String? = nil
    let maxHP: Double
    var currentHP: Double
    /// `var`, not `let`: buffs (Ultimate/Active Skill/boss enrage) modify this
    /// in place. Keep it a `var` rather than reconstructing the whole struct
    /// at each buff site — a prior full-reconstruction call site once forgot
    /// to carry a field across and silently reset it.
    var attack: Double
    let defense: Double
    let speed: Double
    let ultimate: UltimateSkill?
    /// Player units only — see `ActiveSkill` doc comment for the tactical
    /// role it plays alongside the Ultimate.
    var activeSkill: ActiveSkill? = nil
    /// Overrides the default element/role icon for named enemy variety.
    /// `nil` falls back to today's behavior (element symbol, or role symbol
    /// for players).
    var symbol: String? = nil
    /// Overrides `name` for portrait art lookup only (display name stays
    /// `name`). Used by the Arena Tower: a rival's displayed identity is a
    /// flavor team name (e.g. "Team Nachtklinge", see `ArenaSystem`), which
    /// never matches an imageset — but the rival's combat stats are borrowed
    /// wholesale from a real `DreamkeeperDefinition`, which already has real
    /// portrait art. Setting this to that definition's `name` lets the Arena
    /// banner show that real portrait while still displaying the flavor team
    /// name. `nil` everywhere else preserves today's `name`-based lookup.
    var portraitOverrideName: String? = nil
    /// Boss units only.
    var mechanic: BossMechanic? = nil
    /// Guards `.selfHeal`/`.enrage` so they fire exactly once per battle.
    var mechanicTriggered: Bool = false
    /// While > 0, incoming damage is reduced; decrements per hit taken.
    var shieldCharges: Int = 0
    /// Fraction of max HP to revive at, once per battle, the instant this
    /// combatant would otherwise fall — see `PassiveTrait.reviveHPFraction`.
    var reviveHPFraction: Double? = nil
    /// Guards `reviveHPFraction` so it fires exactly once per battle.
    var hasUsedRevive: Bool = false
    /// Extra attack multiplier at 0 HP, scaling linearly down to 0 at full
    /// HP — see `PassiveTrait.lowHPAttackBonus` and `BattleEngine.effectiveAttack`.
    var lowHPAttackBonus: Double? = nil

    /// 0...1 progress toward the next basic attack.
    var attackProgress: Double = 0
    /// 0...attacksToCharge basic attacks landed since last ultimate.
    var energy: Int = 0
    /// Ticks remaining where this combatant cannot act (Control ultimate).
    var stunTicks: Int = 0
    /// Seconds remaining before the Active Skill can be used again.
    var skillCooldownRemaining: Double = 0

    var isAlive: Bool { currentHP > 0 }

    var ultimateReady: Bool {
        guard let ultimate else { return false }
        return energy >= ultimate.attacksToCharge
    }

    var skillReady: Bool {
        guard activeSkill != nil else { return false }
        return skillCooldownRemaining <= 0
    }

    var hpFraction: Double { maxHP > 0 ? max(0, currentHP / maxHP) : 0 }
}
