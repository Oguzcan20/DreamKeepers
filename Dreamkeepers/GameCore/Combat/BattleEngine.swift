import Foundation
import Observation

enum BattleOutcome: Equatable {
    case victory
    case defeat
}

struct BattleLogEntry: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

/// Fired whenever damage lands, so the UI can trigger a purely visual
/// impact (no text) without polling combatant HP every frame.
/// `attackerElement` lets the UI tint the impact effect to match, and
/// `attackerID` lets the attacker's own portrait play a lunge/strike
/// animation distinct from the target's hit-react. `isElementAdvantage`
/// mirrors the same rock-paper-scissors triangle (`Element.multiplier`) so
/// the UI can make a super-effective hit look bigger without recomputing it
/// from raw element values.
struct HitEvent: Equatable {
    let id = UUID()
    let attackerID: UUID
    let targetID: UUID
    let amount: Int
    let attackerElement: Element
    let isElementAdvantage: Bool
}

/// Fired whenever a boss mechanic actually triggers, so the UI can flash a
/// distinct cue (ring pulse + label) beyond the plain log line — otherwise
/// drain/shield/enrage etc. are easy to miss mid-battle.
struct MechanicEvent: Equatable {
    let id = UUID()
    let targetID: UUID
    let mechanic: BossMechanic
}

/// Fired whenever an ultimate is cast, so the UI can trigger a screen shake
/// and glow burst — rarer and more dramatic than a regular hit. `casterID`
/// additionally lets the caster's own party tile pop with a matching burst,
/// the same way `SkillEvent` does for the lighter Active Skill.
struct UltimateEvent: Equatable {
    let id = UUID()
    let casterID: UUID
}

/// Fired whenever an Active Skill is cast, so the UI can give the caster's
/// own tile a quick highlight — lighter than the Ultimate's screen-wide glow.
struct SkillEvent: Equatable {
    let id = UUID()
    let casterID: UUID
}

/// Tick-driven auto-battle simulation. The UI calls `tick(dt:)` on a timer and
/// `activateUltimate(for:)` in response to taps; everything else — targeting,
/// damage, energy, win/loss — happens here so it stays unit-testable without
/// SwiftUI.
@Observable
final class BattleEngine {
    private(set) var combatants: [Combatant]
    private(set) var log: [BattleLogEntry] = []
    private(set) var outcome: BattleOutcome?
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var lastHit: HitEvent?
    private(set) var lastUltimate: UltimateEvent?
    private(set) var lastSkillUse: SkillEvent?
    private(set) var lastMechanicTrigger: MechanicEvent?

    let stage: Int
    let isBossStage: Bool

    /// Injected so tests can make damage deterministic; defaults to a small
    /// +/-10% swing for UI "liveliness".
    var varianceProvider: () -> Double = { Double.random(in: 0.9...1.1) }

    /// Base rate at which attack meters fill, tuned so a 1.0 speed unit
    /// attacks roughly once per second.
    private let attackRateScale: Double = 1.0 / 100.0

    init(playerUnits: [Combatant], enemy: Combatant, stage: Int, isBossStage: Bool) {
        self.combatants = playerUnits + [enemy]
        self.stage = stage
        self.isBossStage = isBossStage
    }

    var playerUnits: [Combatant] { combatants.filter(\.isPlayer) }
    var enemyUnits: [Combatant] { combatants.filter { !$0.isPlayer } }

    func tick(dt: TimeInterval) {
        guard outcome == nil else { return }
        elapsedTime += dt

        for index in combatants.indices {
            guard combatants[index].isAlive else { continue }

            if combatants[index].skillCooldownRemaining > 0 {
                combatants[index].skillCooldownRemaining = max(0, combatants[index].skillCooldownRemaining - dt)
            }

            if combatants[index].stunTicks > 0 {
                combatants[index].stunTicks -= 1
                continue
            }

            combatants[index].attackProgress += dt * combatants[index].speed * attackRateScale
            guard combatants[index].attackProgress >= 1.0 else { continue }
            combatants[index].attackProgress = 0

            performBasicAttack(from: index)
            if outcome != nil { return }
        }
    }

    // MARK: - Basic attacks

    private func performBasicAttack(from attackerIndex: Int) {
        let attacker = combatants[attackerIndex]
        guard let targetIndex = pickTarget(for: attacker) else { return }

        let damage = resolveDamage(attacker: attacker, defender: combatants[targetIndex])
        applyDamage(damage, to: targetIndex, attackerID: attacker.id, attackerName: attacker.name, attackerElement: attacker.element)

        if let ultimate = attacker.ultimate {
            combatants[attackerIndex].energy = min(ultimate.attacksToCharge, combatants[attackerIndex].energy + 1)
        }

        resolveOutcomeIfNeeded()
    }

    private func pickTarget(for attacker: Combatant) -> Int? {
        let candidates = combatants.indices.filter { combatants[$0].isPlayer != attacker.isPlayer && combatants[$0].isAlive }
        if attacker.isPlayer {
            // Players focus the (single) enemy.
            return candidates.first
        }
        // Enemy picks the lowest-HP-fraction ally — mildly punishes a glassy team.
        return candidates.min { combatants[$0].hpFraction < combatants[$1].hpFraction }
    }

    private func resolveDamage(attacker: Combatant, defender: Combatant, multiplier: Double = 1.0) -> Double {
        let elementMultiplier = attacker.element.multiplier(against: defender.element)
        let raw = effectiveAttack(attacker) * elementMultiplier * multiplier - defender.defense * 0.5
        let variance = varianceProvider()
        return max(1, raw * variance)
    }

    /// Layers `lowHPAttackBonus` on top of the (possibly already-buffed)
    /// stored `attack` at the moment damage is computed, rather than
    /// mutating `attack` itself — the bonus tracks current HP live instead
    /// of being baked in once.
    private func effectiveAttack(_ combatant: Combatant) -> Double {
        guard let bonus = combatant.lowHPAttackBonus else { return combatant.attack }
        return combatant.attack * (1 + bonus * (1 - combatant.hpFraction))
    }

    private func applyDamage(_ damage: Double, to index: Int, attackerID: UUID, attackerName: String, attackerElement: Element) {
        var damage = damage
        if combatants[index].shieldCharges > 0 {
            damage *= 0.4
            combatants[index].shieldCharges -= 1
            if combatants[index].shieldCharges == 0 {
                appendLog("\(combatants[index].name)'s shield shatters!")
            }
        }

        let amount = Int(damage.rounded())
        let newHP = combatants[index].currentHP - damage
        if newHP <= 0, combatants[index].isPlayer, let reviveFraction = combatants[index].reviveHPFraction, !combatants[index].hasUsedRevive {
            combatants[index].currentHP = combatants[index].maxHP * reviveFraction
            combatants[index].hasUsedRevive = true
            appendLog("\(combatants[index].name) refuses to fall, surging back with the tide!")
        } else {
            combatants[index].currentHP = max(0, newHP)
        }
        let isAdvantage = attackerElement.multiplier(against: combatants[index].element) > 1.0
        lastHit = HitEvent(attackerID: attackerID, targetID: combatants[index].id, amount: amount, attackerElement: attackerElement, isElementAdvantage: isAdvantage)
        appendLog("\(attackerName) hits \(combatants[index].name) for \(amount).")
        if !combatants[index].isAlive {
            appendLog("\(combatants[index].name) falls.")
        }
        triggerBossMechanicIfNeeded(at: index)
    }

    // MARK: - Ultimates

    @discardableResult
    func activateUltimate(for id: UUID) -> Bool {
        guard outcome == nil,
              let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].isAlive,
              combatants[index].ultimateReady,
              let ultimate = combatants[index].ultimate else { return false }

        combatants[index].energy = 0
        lastUltimate = UltimateEvent(casterID: combatants[index].id)
        appendLog("\(combatants[index].name) unleashes \(ultimate.name)!")

        switch combatants[index].role {
        case .healer:
            healAllies(caster: combatants[index], multiplier: ultimate.damageMultiplier)
        case .support:
            buffAllies(caster: combatants[index], multiplier: ultimate.damageMultiplier)
        case .control:
            strikeEnemyAndStun(from: index, multiplier: ultimate.damageMultiplier)
        case .tank, .damage:
            strikeEnemy(from: index, multiplier: ultimate.damageMultiplier)
        case .guardian:
            shieldAllies(caster: combatants[index], multiplier: ultimate.damageMultiplier)
        }

        resolveOutcomeIfNeeded()
        return true
    }

    private func strikeEnemy(from index: Int, multiplier: Double) {
        guard let targetIndex = pickTarget(for: combatants[index]) else { return }
        let damage = resolveDamage(attacker: combatants[index], defender: combatants[targetIndex], multiplier: multiplier)
        applyDamage(damage, to: targetIndex, attackerID: combatants[index].id, attackerName: combatants[index].name, attackerElement: combatants[index].element)
    }

    private func strikeEnemyAndStun(from index: Int, multiplier: Double) {
        guard let targetIndex = pickTarget(for: combatants[index]) else { return }
        let damage = resolveDamage(attacker: combatants[index], defender: combatants[targetIndex], multiplier: multiplier)
        applyDamage(damage, to: targetIndex, attackerID: combatants[index].id, attackerName: combatants[index].name, attackerElement: combatants[index].element)
        if combatants[targetIndex].isAlive {
            combatants[targetIndex].stunTicks = 20
            appendLog("\(combatants[targetIndex].name) is frozen still!")
        }
    }

    private func healAllies(caster: Combatant, multiplier: Double) {
        let healAmount = caster.attack * multiplier
        for index in combatants.indices where combatants[index].isPlayer && combatants[index].isAlive {
            combatants[index].currentHP = min(combatants[index].maxHP, combatants[index].currentHP + healAmount)
        }
        appendLog("The team is bathed in moonlight, healing for \(Int(healAmount.rounded())).")
    }

    private func buffAllies(caster: Combatant, multiplier: Double) {
        for index in combatants.indices where combatants[index].isPlayer && combatants[index].isAlive {
            combatants[index].attack *= (1 + (multiplier - 1) * 0.5)
        }
        appendLog("\(caster.name) empowers the whole team!")
    }

    private func shieldAllies(caster: Combatant, multiplier: Double) {
        let charges = max(1, Int((3 * multiplier).rounded()))
        for index in combatants.indices where combatants[index].isPlayer && combatants[index].isAlive {
            combatants[index].shieldCharges = charges
        }
        appendLog("\(caster.name) raises a wall of water around the team!")
    }

    // MARK: - Active Skill

    /// Player-only, quick tactical action on a short real-time cooldown —
    /// independent of the Ultimate's attack-count energy meter so the two
    /// buttons feel distinct (frequent tap vs. saved-up payoff).
    @discardableResult
    func activateSkill(for id: UUID) -> Bool {
        guard outcome == nil,
              let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].isPlayer,
              combatants[index].isAlive,
              combatants[index].skillReady,
              let skill = combatants[index].activeSkill else { return false }

        combatants[index].skillCooldownRemaining = skill.cooldownSeconds
        lastSkillUse = SkillEvent(casterID: combatants[index].id)
        appendLog("\(combatants[index].name) uses \(skill.name).")

        switch combatants[index].role {
        case .healer:
            healLowestAlly(caster: combatants[index], multiplier: skill.effectMultiplier)
        case .support:
            buffSelf(index: index, multiplier: skill.effectMultiplier)
        case .tank, .damage, .control:
            quickStrike(from: index, multiplier: skill.effectMultiplier)
        case .guardian:
            quickStrikeAndSlow(from: index, multiplier: skill.effectMultiplier)
        }

        resolveOutcomeIfNeeded()
        return true
    }

    private func quickStrike(from index: Int, multiplier: Double) {
        guard let targetIndex = pickTarget(for: combatants[index]) else { return }
        let damage = resolveDamage(attacker: combatants[index], defender: combatants[targetIndex], multiplier: multiplier)
        applyDamage(damage, to: targetIndex, attackerID: combatants[index].id, attackerName: combatants[index].name, attackerElement: combatants[index].element)
    }

    private func healLowestAlly(caster: Combatant, multiplier: Double) {
        let allies = combatants.indices.filter { combatants[$0].isPlayer && combatants[$0].isAlive }
        guard let targetIndex = allies.min(by: { combatants[$0].hpFraction < combatants[$1].hpFraction }) else { return }
        let healAmount = caster.attack * multiplier
        combatants[targetIndex].currentHP = min(combatants[targetIndex].maxHP, combatants[targetIndex].currentHP + healAmount)
        appendLog("\(combatants[targetIndex].name) is soothed for \(Int(healAmount.rounded())).")
    }

    private func buffSelf(index: Int, multiplier: Double) {
        combatants[index].attack *= (1 + (multiplier - 1) * 0.5)
        appendLog("\(combatants[index].name) steels themself.")
    }

    private func quickStrikeAndSlow(from index: Int, multiplier: Double) {
        guard let targetIndex = pickTarget(for: combatants[index]) else { return }
        let damage = resolveDamage(attacker: combatants[index], defender: combatants[targetIndex], multiplier: multiplier)
        applyDamage(damage, to: targetIndex, attackerID: combatants[index].id, attackerName: combatants[index].name, attackerElement: combatants[index].element)
        if combatants[targetIndex].isAlive {
            combatants[targetIndex].stunTicks = 10
            appendLog("\(combatants[targetIndex].name) is caught in the current, slowed!")
        }
    }

    // MARK: - Boss mechanics

    /// Checked after every hit lands on a boss — `.selfHeal`/`.enrage` are
    /// one-shot HP-threshold triggers; `.shield` is handled entirely in
    /// `applyDamage` and needs no per-hit check here.
    private func triggerBossMechanicIfNeeded(at index: Int) {
        guard combatants[index].isBoss, combatants[index].isAlive,
              !combatants[index].mechanicTriggered,
              let mechanic = combatants[index].mechanic else { return }

        switch mechanic {
        case .selfHeal:
            guard combatants[index].hpFraction <= 0.5 else { return }
            let healAmount = combatants[index].maxHP * 0.25
            combatants[index].currentHP = min(combatants[index].maxHP, combatants[index].currentHP + healAmount)
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) calls on hidden reserves, healing for \(Int(healAmount.rounded()))!")
        case .enrage:
            guard combatants[index].hpFraction <= 0.3 else { return }
            combatants[index].attack *= 1.5
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) flies into a rage, striking harder!")
        case .shield:
            break
        case .drain:
            guard combatants[index].hpFraction <= 0.5 else { return }
            for i in combatants.indices where combatants[i].isPlayer {
                combatants[i].energy = 0
            }
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) drains the team's resolve!")
        case .regenShield:
            guard combatants[index].hpFraction <= 0.5 else { return }
            combatants[index].shieldCharges = 3
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) grows a fresh shield of roots!")
        case .phaseShift:
            guard combatants[index].hpFraction <= 0.5 else { return }
            combatants[index].attack *= 1.35
            combatants[index].shieldCharges = 3
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) turns from light to shadow!")
        case .sovereign:
            guard combatants[index].hpFraction <= 0.4 else { return }
            let healAmount = combatants[index].maxHP * 0.2
            combatants[index].currentHP = min(combatants[index].maxHP, combatants[index].currentHP + healAmount)
            combatants[index].attack *= 1.5
            combatants[index].shieldCharges = 3
            combatants[index].mechanicTriggered = true
            appendLog("\(combatants[index].name) awakens its final, sovereign form!")
        }

        // Every case above either `return`s early (not yet triggered) or
        // falls through here having just set `mechanicTriggered` — except
        // `.shield`, which has no distinct "trigger moment" to flash.
        if mechanic != .shield {
            lastMechanicTrigger = MechanicEvent(targetID: combatants[index].id, mechanic: mechanic)
        }
    }

    // MARK: - Outcome

    private func resolveOutcomeIfNeeded() {
        if enemyUnits.allSatisfy({ !$0.isAlive }) {
            outcome = .victory
            appendLog("Victory!")
        } else if playerUnits.allSatisfy({ !$0.isAlive }) {
            outcome = .defeat
            appendLog("Defeat...")
        }
    }

    private func appendLog(_ text: String) {
        log.append(BattleLogEntry(text: text))
        if log.count > 40 { log.removeFirst(log.count - 40) }
    }
}
