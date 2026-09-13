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
    /// True if the defender had `Guard` active for this hit (see
    /// `BattleEngine.activateGuard`) — damage was already reduced before
    /// this event fired; the UI uses this only to show a "Blocked!" cue.
    var wasGuarded: Bool = false
    /// True if Guard was tapped inside the telegraph's last
    /// `BattleEngine.justGuardWindow` seconds — a near-full block, shown
    /// distinctly from a plain Guard.
    var wasPerfectGuard: Bool = false
}

/// Fired the instant an enemy commits to its next basic attack instead of
/// firing it right away — the player's window to tap Guard on the threatened
/// ally. See `BattleEngine.beginTelegraph`.
struct TelegraphEvent: Equatable {
    let id = UUID()
    let attackerID: UUID
    let targetID: UUID
}

/// Fired when a tap on a player unit's own portrait resolves — lets the UI
/// show "Perfect!"/"Good"/"Too Early" floating feedback on that exact tile.
enum TapQuality: Equatable {
    case perfect
    case good
    case tooEarly
}
struct TapFeedbackEvent: Equatable {
    let id = UUID()
    let combatantID: UUID
    let quality: TapQuality
}

/// Fired when the combo meter hits a multiple of 5 and a free bonus hit
/// fires from a random living ally — see `BattleEngine.triggerChainBurst`.
struct ChainBurstEvent: Equatable {
    let id = UUID()
    let casterID: UUID
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
    /// True when this Ultimate was cast at combo x10+ — see
    /// `BattleEngine.comboFinisherThreshold` — and got the damage bonus.
    var isFinisher: Bool = false
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
    private(set) var lastTelegraph: TelegraphEvent?
    private(set) var lastTapFeedback: TapFeedbackEvent?
    private(set) var lastChainBurst: ChainBurstEvent?

    /// Hits (by a player, or a player-caused Chain Burst) landed back to back
    /// within `comboWindow` of one another. Resets to 1 whenever the gap is
    /// larger — see `applyDamage`. Drives Chain Bursts and the Ultimate's
    /// Finisher bonus, and is shown live in the UI as momentum, not just a
    /// tally.
    private(set) var comboCount: Int = 0
    private var lastComboHitTime: TimeInterval = -.greatestFiniteMagnitude

    let stage: Int
    let isBossStage: Bool

    /// Multiplies every point of damage a player unit deals — folds in
    /// Rebirth's `SoulUpgrade.damage` track (see `GameState.soulDamageMult`).
    /// `1.0` for a battle with no Soul upgrades bought.
    let playerDamageMultiplier: Double

    /// Enemies still waiting to enter the fight after the current one(s) die
    /// — a Dungeon run's remaining waves. Empty for an ordinary single-enemy
    /// battle (Campaign/Arena).
    private var pendingWaves: [Combatant]
    /// 1-indexed wave currently being fought. `1` for an ordinary battle.
    private(set) var currentWave: Int = 1
    /// Total waves this run will fight — fixed at construction. `1` for an
    /// ordinary battle.
    let totalWaves: Int

    /// Injected so tests can make damage deterministic; defaults to a small
    /// +/-10% swing for UI "liveliness".
    var varianceProvider: () -> Double = { Double.random(in: 0.9...1.1) }

    /// Base rate at which attack meters fill, tuned so a 1.0 speed unit
    /// attacks roughly once per second.
    private let attackRateScale: Double = 1.0 / 100.0

    // MARK: - Active Combat tuning

    /// Gauge fraction at which an enemy commits to its wind-up instead of
    /// continuing to fill toward 1.0 — enemies always telegraph, never
    /// insta-fire, however large a single `tick(dt:)` step is.
    static let telegraphTriggerProgress: Double = 0.85
    /// Real seconds a wind-up holds before the attack actually lands.
    static let telegraphDuration: TimeInterval = 0.9
    /// The last slice of `telegraphDuration` in which tapping Guard counts as
    /// a Just Guard (bigger block, staggers the attacker) rather than a
    /// plain one.
    private static let justGuardWindow: TimeInterval = 0.3
    /// Gauge fraction at which tapping a player's own portrait fires its
    /// attack early instead of doing nothing.
    static let manualTapThreshold: Double = 0.7
    /// Gauge fraction at which an early tap counts as Perfect instead of Good.
    static let perfectTapThreshold: Double = 0.9
    /// Damage multiplier for a Perfect / Good early tap.
    private static let perfectTapMultiplier: Double = 1.5
    private static let goodTapMultiplier: Double = 1.2
    /// Consecutive player-caused hits within this many seconds of one another
    /// keep the combo alive; a bigger gap resets it.
    private static let comboWindow: TimeInterval = 1.5

    /// Tolerance for floating-point drift in accumulated `Double` gauges and
    /// timers (`attackProgress`, `elapsedTime`, `telegraphRemaining`): many
    /// small `dt` ticks summing to an intended boundary like `1.0` can land
    /// at e.g. `0.9999999999999999` instead, which would otherwise flip a
    /// `>=`/`<=` threshold comparison the wrong way for exactly one extra
    /// tick. Every such comparison below is nudged by this amount rather
    /// than compared exactly.
    private static let timingEpsilon: Double = 1e-6
    /// Combo count at which the Ultimate deals bonus Finisher damage. Not
    /// `private`: the UI colors the combo counter gold once it's reached.
    static let comboFinisherThreshold: Int = 10
    private static let finisherMultiplier: Double = 1.3
    /// Chain Burst fires every time the combo crosses a multiple of this.
    private static let chainBurstInterval: Int = 5
    private static let chainBurstMultiplier: Double = 0.5

    init(
        playerUnits: [Combatant], enemy: Combatant, stage: Int, isBossStage: Bool,
        reinforcements: [Combatant] = [], playerDamageMultiplier: Double = 1.0
    ) {
        self.combatants = playerUnits + [enemy]
        self.stage = stage
        self.isBossStage = isBossStage
        self.pendingWaves = reinforcements
        self.totalWaves = 1 + reinforcements.count
        self.playerDamageMultiplier = playerDamageMultiplier
    }

    var playerUnits: [Combatant] { combatants.filter(\.isPlayer) }
    var enemyUnits: [Combatant] { combatants.filter { !$0.isPlayer } }

    /// The enemy currently being fought — the first still-alive one, or the
    /// last enemy if none remain (so the UI has something to show while the
    /// outcome/next-wave transition is being resolved).
    var activeEnemy: Combatant? {
        enemyUnits.first(where: \.isAlive) ?? enemyUnits.last
    }

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

            if combatants[index].isTelegraphing {
                combatants[index].telegraphRemaining -= dt
                if combatants[index].telegraphRemaining <= Self.timingEpsilon {
                    resolveTelegraphedAttack(at: index)
                    if outcome != nil { return }
                }
                continue
            }

            combatants[index].attackProgress += dt * combatants[index].speed * attackRateScale

            if !combatants[index].isPlayer {
                // Enemies never insta-fire: as soon as the gauge crosses the
                // trigger threshold (even if a single large `dt` jumped it
                // straight past 1.0) they commit to a visible wind-up instead
                // — see `beginTelegraph`.
                if combatants[index].attackProgress >= Self.telegraphTriggerProgress - Self.timingEpsilon {
                    beginTelegraph(at: index)
                }
                continue
            }

            guard combatants[index].attackProgress >= 1.0 - Self.timingEpsilon else { continue }
            combatants[index].attackProgress = 0

            performBasicAttack(from: index)
            if outcome != nil { return }
        }
    }

    // MARK: - Basic attacks

    private func performBasicAttack(from attackerIndex: Int, damageMultiplier: Double = 1.0) {
        let attacker = combatants[attackerIndex]
        guard let targetIndex = pickTarget(for: attacker) else { return }

        let damage = resolveDamage(attacker: attacker, defender: combatants[targetIndex], multiplier: damageMultiplier)
        applyDamage(damage, to: targetIndex, attackerID: attacker.id, attackerName: attacker.name, attackerElement: attacker.element)

        if let ultimate = attacker.ultimate {
            combatants[attackerIndex].energy = min(ultimate.attacksToCharge, combatants[attackerIndex].energy + 1)
        }

        resolveOutcomeIfNeeded()
    }

    // MARK: - Active input: tap-to-attack

    /// Called when the player taps a party member's own portrait. Below
    /// `manualTapThreshold` it's just a "not yet" shake; from there to
    /// `perfectTapThreshold` it fires the attack early at a Good bonus;
    /// above that, at a bigger Perfect bonus. Ignoring the gauge entirely
    /// still works exactly as before — it auto-fires at 1.0 for normal
    /// damage — so idle/AFK play is untouched by this.
    @discardableResult
    func tapAttack(for id: UUID) -> TapQuality? {
        guard outcome == nil,
              let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].isPlayer,
              combatants[index].isAlive,
              combatants[index].stunTicks == 0 else { return nil }

        let progress = combatants[index].attackProgress
        guard progress >= Self.manualTapThreshold - Self.timingEpsilon else {
            lastTapFeedback = TapFeedbackEvent(combatantID: id, quality: .tooEarly)
            return .tooEarly
        }

        let quality: TapQuality = progress >= Self.perfectTapThreshold - Self.timingEpsilon ? .perfect : .good
        let multiplier = quality == .perfect ? Self.perfectTapMultiplier : Self.goodTapMultiplier
        combatants[index].attackProgress = 0
        performBasicAttack(from: index, damageMultiplier: multiplier)
        lastTapFeedback = TapFeedbackEvent(combatantID: id, quality: quality)
        return quality
    }

    // MARK: - Enemy telegraph & Guard

    /// An enemy has committed to its next basic attack: freezes the target
    /// (so the threat indicator doesn't jump mid-wind-up) and starts the
    /// real-time countdown to impact.
    private func beginTelegraph(at index: Int) {
        guard let targetIndex = pickTarget(for: combatants[index]) else { return }
        combatants[index].isTelegraphing = true
        combatants[index].telegraphRemaining = Self.telegraphDuration
        combatants[index].telegraphTargetID = combatants[targetIndex].id
        lastTelegraph = TelegraphEvent(attackerID: combatants[index].id, targetID: combatants[targetIndex].id)
    }

    /// Tapping Guard while an ally is threatened. Anytime during the
    /// wind-up halves the hit; tapping inside the last `justGuardWindow`
    /// seconds nearly nullifies it and staggers the attacker instead.
    @discardableResult
    func activateGuard(for defenderID: UUID) -> Bool {
        guard outcome == nil,
              let enemyIndex = combatants.firstIndex(where: { $0.isTelegraphing && $0.telegraphTargetID == defenderID }),
              let defenderIndex = combatants.firstIndex(where: { $0.id == defenderID }),
              combatants[defenderIndex].isAlive,
              !combatants[defenderIndex].guardActive else { return false }

        combatants[defenderIndex].guardActive = true
        combatants[defenderIndex].guardIsPerfect = combatants[enemyIndex].telegraphRemaining <= Self.justGuardWindow + Self.timingEpsilon
        return true
    }

    private func resolveTelegraphedAttack(at attackerIndex: Int) {
        let attacker = combatants[attackerIndex]
        combatants[attackerIndex].isTelegraphing = false
        combatants[attackerIndex].telegraphRemaining = 0

        var targetIndex: Int?
        if let targetID = attacker.telegraphTargetID,
           let index = combatants.firstIndex(where: { $0.id == targetID }), combatants[index].isAlive {
            targetIndex = index
        } else {
            targetIndex = pickTarget(for: attacker)
        }
        combatants[attackerIndex].telegraphTargetID = nil
        combatants[attackerIndex].attackProgress = 0
        guard let targetIndex else { return }

        var damage = resolveDamage(attacker: attacker, defender: combatants[targetIndex])
        var wasGuarded = false
        var wasPerfectGuard = false
        if combatants[targetIndex].guardActive {
            wasGuarded = true
            wasPerfectGuard = combatants[targetIndex].guardIsPerfect
            damage *= wasPerfectGuard ? 0.2 : 0.5
            combatants[targetIndex].guardActive = false
            combatants[targetIndex].guardIsPerfect = false
            if wasPerfectGuard {
                combatants[attackerIndex].stunTicks = 15
                appendLog("\(combatants[targetIndex].name) parries perfectly, staggering \(attacker.name)!")
            } else {
                appendLog("\(combatants[targetIndex].name) blocks part of the blow!")
            }
        }

        applyDamage(damage, to: targetIndex, attackerID: attacker.id, attackerName: attacker.name, attackerElement: attacker.element,
                    wasGuarded: wasGuarded, wasPerfectGuard: wasPerfectGuard)

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
        let soulMultiplier = attacker.isPlayer ? playerDamageMultiplier : 1.0
        let raw = effectiveAttack(attacker) * elementMultiplier * multiplier * soulMultiplier - defender.defense * 0.5
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

    private func applyDamage(
        _ damage: Double, to index: Int, attackerID: UUID, attackerName: String, attackerElement: Element,
        wasGuarded: Bool = false, wasPerfectGuard: Bool = false
    ) {
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
        lastHit = HitEvent(attackerID: attackerID, targetID: combatants[index].id, amount: amount, attackerElement: attackerElement,
                            isElementAdvantage: isAdvantage, wasGuarded: wasGuarded, wasPerfectGuard: wasPerfectGuard)
        appendLog("\(attackerName) hits \(combatants[index].name) for \(amount).")
        if !combatants[index].isAlive {
            appendLog("\(combatants[index].name) falls.")
        }
        triggerBossMechanicIfNeeded(at: index)
        updateCombo(attackerID: attackerID, targetIndex: index)
    }

    /// Only player-caused hits (basic attacks, Skill, Ultimate, Chain Burst)
    /// build momentum — an enemy landing its own attack never breaks or
    /// grows it directly, so the meter reads purely as "how well is the
    /// player pressing the advantage" rather than a shared tug-of-war.
    private func updateCombo(attackerID: UUID, targetIndex: Int) {
        guard let attacker = combatants.first(where: { $0.id == attackerID }), attacker.isPlayer else { return }

        if elapsedTime - lastComboHitTime <= Self.comboWindow + Self.timingEpsilon {
            comboCount += 1
        } else {
            comboCount = 1
        }
        lastComboHitTime = elapsedTime

        if comboCount > 0, comboCount % Self.chainBurstInterval == 0 {
            triggerChainBurst(against: targetIndex)
        }
    }

    private func triggerChainBurst(against targetIndex: Int) {
        guard combatants[targetIndex].isAlive else { return }
        let allies = combatants.indices.filter { combatants[$0].isPlayer && combatants[$0].isAlive }
        guard let casterIndex = allies.randomElement() else { return }

        let damage = resolveDamage(attacker: combatants[casterIndex], defender: combatants[targetIndex], multiplier: Self.chainBurstMultiplier)
        lastChainBurst = ChainBurstEvent(casterID: combatants[casterIndex].id)
        appendLog("Chain Burst! \(combatants[casterIndex].name) joins the assault!")
        applyDamage(damage, to: targetIndex, attackerID: combatants[casterIndex].id, attackerName: combatants[casterIndex].name, attackerElement: combatants[casterIndex].element)
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
        let isFinisher = comboCount >= Self.comboFinisherThreshold
        let effectiveMultiplier = ultimate.damageMultiplier * (isFinisher ? Self.finisherMultiplier : 1.0)
        lastUltimate = UltimateEvent(casterID: combatants[index].id, isFinisher: isFinisher)
        appendLog(isFinisher
            ? "\(combatants[index].name) unleashes \(ultimate.name) with the momentum of an unbroken assault!"
            : "\(combatants[index].name) unleashes \(ultimate.name)!")

        switch combatants[index].role {
        case .healer:
            healAllies(caster: combatants[index], multiplier: effectiveMultiplier)
        case .support:
            buffAllies(caster: combatants[index], multiplier: effectiveMultiplier)
        case .control:
            strikeEnemyAndStun(from: index, multiplier: effectiveMultiplier)
        case .tank, .damage:
            strikeEnemy(from: index, multiplier: effectiveMultiplier)
        case .guardian:
            shieldAllies(caster: combatants[index], multiplier: effectiveMultiplier)
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
        guard outcome == nil else { return }

        if enemyUnits.allSatisfy({ !$0.isAlive }) {
            if !pendingWaves.isEmpty {
                let next = pendingWaves.removeFirst()
                combatants.append(next)
                currentWave += 1
                appendLog("A new foe advances: \(next.name)!")
                return
            }
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
