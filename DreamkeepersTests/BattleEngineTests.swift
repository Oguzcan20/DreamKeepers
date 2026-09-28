import XCTest
@testable import Dreamkeepers

final class BattleEngineTests: XCTestCase {
    private func makeUnit(name: String, isPlayer: Bool, hp: Double, attack: Double, defense: Double = 5,
                           speed: Double = 50, role: Role = .damage, ultimate: UltimateSkill? = nil,
                           activeSkill: ActiveSkill? = nil, currentHP: Double? = nil,
                           isBoss: Bool = false, mechanic: BossMechanic? = nil, shieldCharges: Int = 0) -> Combatant {
        Combatant(id: UUID(), name: name, element: .ember, role: role, isPlayer: isPlayer, isBoss: isBoss,
                  maxHP: hp, currentHP: currentHP ?? hp, attack: attack, defense: defense, speed: speed,
                  ultimate: ultimate, activeSkill: activeSkill, mechanic: mechanic, shieldCharges: shieldCharges)
    }

    func testStrongTeamDefeatsWeakEnemy() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 40, speed: 80)
        let enemy = makeUnit(name: "Weakling", isPlayer: false, hp: 30, attack: 2, speed: 20)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }

        XCTAssertEqual(engine.outcome, .victory)
    }

    func testWeakTeamLosesToStrongEnemy() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 20, attack: 2, speed: 20)
        let enemy = makeUnit(name: "Titan", isPlayer: false, hp: 500, attack: 50, speed: 80)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }

        XCTAssertEqual(engine.outcome, .defeat)
    }

    func testUltimateNotReadyInitially() {
        let ultimate = UltimateSkill(name: "Test Blast", description: "", damageMultiplier: 2, attacksToCharge: 3)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10, ultimate: ultimate)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertFalse(engine.activateUltimate(for: hero.id))
    }

    func testUltimateBecomesReadyAfterEnoughAttacks() {
        let ultimate = UltimateSkill(name: "Test Blast", description: "", damageMultiplier: 2, attacksToCharge: 2)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10, speed: 100, ultimate: ultimate)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 10_000, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<40 { engine.tick(dt: 0.1) }

        XCTAssertTrue(engine.playerUnits.first?.ultimateReady ?? false)
        XCTAssertTrue(engine.activateUltimate(for: hero.id))
    }

    // MARK: - Active Skill

    func testUnitWithoutActiveSkillCannotUseOne() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertFalse(engine.activateSkill(for: hero.id))
    }

    func testActiveSkillIsUsableImmediatelyUnlikeUltimate() {
        let skill = ActiveSkill(name: "Jab", description: "", effectMultiplier: 1.3, cooldownSeconds: 6)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10, activeSkill: skill)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        XCTAssertTrue(engine.playerUnits.first?.skillReady ?? false, "No basic attacks needed — the skill has its own cooldown, not the ultimate's energy meter")
        XCTAssertTrue(engine.activateSkill(for: hero.id))
    }

    func testActiveSkillGoesOnCooldownAndRecoversOverTime() {
        let skill = ActiveSkill(name: "Jab", description: "", effectMultiplier: 1.3, cooldownSeconds: 5)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10, activeSkill: skill)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        XCTAssertTrue(engine.activateSkill(for: hero.id))
        XCTAssertFalse(engine.playerUnits.first?.skillReady ?? true)
        XCTAssertFalse(engine.activateSkill(for: hero.id), "Can't reuse while on cooldown")

        for _ in 0..<60 { engine.tick(dt: 0.1) } // 6s of ticks, cooldown is 5s

        XCTAssertTrue(engine.playerUnits.first?.skillReady ?? false)
        XCTAssertTrue(engine.activateSkill(for: hero.id))
    }

    func testEnemyCombatantsCannotUseActiveSkills() {
        let skill = ActiveSkill(name: "Jab", description: "", effectMultiplier: 1.3, cooldownSeconds: 5)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 10)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 1, activeSkill: skill)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertFalse(engine.activateSkill(for: enemy.id))
    }

    func testDamageRoleActiveSkillStrikesTheEnemy() {
        let skill = ActiveSkill(name: "Jab", description: "", effectMultiplier: 1.3, cooldownSeconds: 5)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 20, role: .damage, activeSkill: skill)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, defense: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        XCTAssertTrue(engine.activateSkill(for: hero.id))
        XCTAssertLessThan(engine.enemyUnits.first!.currentHP, 1000)
    }

    func testHealerRoleActiveSkillHealsTheLowestHPAlly() {
        let skill = ActiveSkill(name: "Soothe", description: "", effectMultiplier: 1.0, cooldownSeconds: 5)
        let healer = makeUnit(name: "Healer", isPlayer: true, hp: 100, attack: 20, role: .healer, activeSkill: skill)
        let damagedAlly = makeUnit(name: "Ally", isPlayer: true, hp: 100, attack: 10, currentHP: 40)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [healer, damagedAlly], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertTrue(engine.activateSkill(for: healer.id))
        let healedAlly = engine.playerUnits.first { $0.name == "Ally" }!
        XCTAssertGreaterThan(healedAlly.currentHP, 40)
        XCTAssertEqual(engine.playerUnits.first { $0.name == "Healer" }!.currentHP, 100, "Full-HP caster shouldn't be the heal target while an ally is hurt")
    }

    func testSupportRoleActiveSkillBuffsItsOwnAttack() {
        let skill = ActiveSkill(name: "Rally", description: "", effectMultiplier: 1.4, cooldownSeconds: 5)
        let support = makeUnit(name: "Support", isPlayer: true, hp: 100, attack: 20, role: .support, activeSkill: skill)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [support], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertTrue(engine.activateSkill(for: support.id))
        XCTAssertGreaterThan(engine.playerUnits.first!.attack, 20)
    }

    // MARK: - Boss mechanics

    func testBossSelfHealsOnceBelowHalfHP() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 70, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .selfHeal)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 5, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // exactly one hero attack lands (10 ticks/attack)

        let updatedBoss = engine.enemyUnits.first!
        XCTAssertTrue(updatedBoss.mechanicTriggered)
        XCTAssertEqual(updatedBoss.currentHP, 55, accuracy: 0.5) // 100 - 70 dmg + 25% heal
    }

    func testBossSelfHealOnlyTriggersOnce() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 300, attack: 120, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 200, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .selfHeal)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 5, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<25 { engine.tick(dt: 0.1) } // exactly two hero attacks land

        // Hit 1: 200-120=80 (40%) -> heals +50 -> 130. Hit 2: 130-120=10, no second heal.
        let updatedBoss = engine.enemyUnits.first!
        XCTAssertEqual(updatedBoss.currentHP, 10, accuracy: 0.5)
    }

    func testBossEnragesOnceBelowThirtyPercentHP() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 75, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 20, defense: 0, speed: 1,
                             isBoss: true, mechanic: .enrage)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 10, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) }

        let updatedBoss = engine.enemyUnits.first!
        XCTAssertTrue(updatedBoss.mechanicTriggered)
        XCTAssertEqual(updatedBoss.attack, 30, accuracy: 0.01) // 20 * 1.5
    }

    func testBossShieldReducesDamageThenDepletes() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 300, attack: 100, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 1000, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .shield, shieldCharges: 3)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 15, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<45 { engine.tick(dt: 0.1) } // exactly four hero attacks land

        // Hits 1-3 reduced to 40 each (shield), hit 4 lands full at 100.
        let updatedBoss = engine.enemyUnits.first!
        XCTAssertEqual(updatedBoss.shieldCharges, 0)
        XCTAssertEqual(updatedBoss.currentHP, 780, accuracy: 1)
    }

    func testBossDrainResetsPlayerEnergyOnceBelowHalfHP() {
        // attacksToCharge is high enough that energy never caps on its own,
        // isolating the drain's reset from the normal "gain 1 per hit" charge.
        let ultimate = UltimateSkill(name: "Strike", description: "", damageMultiplier: 1.5, attacksToCharge: 5)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 40, speed: 100, ultimate: ultimate)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .drain)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 5, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        // Hit 1: 100 -> 60 (60%, above threshold), energy 0 -> 1.
        // Hit 2: 60 -> 20 (20%, crosses 50%): drain resets energy to 0, then
        // the hit's own charge brings it to 1 — without drain it would be 2.
        for _ in 0..<25 { engine.tick(dt: 0.1) }

        XCTAssertTrue(engine.enemyUnits.first!.mechanicTriggered)
        XCTAssertEqual(engine.playerUnits.first!.energy, 1, "drain should reset energy on the hit that crosses 50% HP, before that hit's own charge is added")
    }

    func testBossRegenShieldGrantsChargesOnceBelowHalfHP() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 300, attack: 60, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .regenShield)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 40, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // one hero attack lands, dropping boss below 50%

        let updatedBoss = engine.enemyUnits.first!
        XCTAssertTrue(updatedBoss.mechanicTriggered)
        XCTAssertEqual(updatedBoss.shieldCharges, 3)
    }

    func testBossPhaseShiftBuffsAttackAndGrantsShieldOnceBelowHalfHP() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 300, attack: 60, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 20, defense: 0, speed: 1,
                             isBoss: true, mechanic: .phaseShift)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 45, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) }

        let updatedBoss = engine.enemyUnits.first!
        XCTAssertTrue(updatedBoss.mechanicTriggered)
        XCTAssertEqual(updatedBoss.attack, 27, accuracy: 0.01) // 20 * 1.35
        XCTAssertEqual(updatedBoss.shieldCharges, 3)
    }

    func testBossSovereignHealsBuffsAndShieldsOnceBelowFortyPercentHP() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 400, attack: 65, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 20, defense: 0, speed: 1,
                             isBoss: true, mechanic: .sovereign)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 50, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // one hit: 100 - 65 = 35 (35%, under 40%)

        let updatedBoss = engine.enemyUnits.first!
        XCTAssertTrue(updatedBoss.mechanicTriggered)
        XCTAssertEqual(updatedBoss.currentHP, 55, accuracy: 0.5) // 35 + 20% of 100
        XCTAssertEqual(updatedBoss.attack, 30, accuracy: 0.01) // 20 * 1.5
        XCTAssertEqual(updatedBoss.shieldCharges, 3)
    }

    func testMechanicsNeverTriggerForNonBossCombatants() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 80, speed: 100)
        let enemy = makeUnit(name: "Regular", isPlayer: false, hp: 100, attack: 0, defense: 0, speed: 1,
                              isBoss: false, mechanic: .selfHeal)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) }

        let updated = engine.enemyUnits.first!
        XCTAssertFalse(updated.mechanicTriggered)
        XCTAssertEqual(updated.currentHP, 20, accuracy: 0.5)
    }

    // MARK: - Visual effect events

    func testHitEventCarriesTheAttackersElement() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 40, speed: 100)
        let enemy = makeUnit(name: "Weakling", isPlayer: false, hp: 300, attack: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // one hero attack lands

        XCTAssertEqual(engine.lastHit?.attackerElement, .ember, "makeUnit's default element is .ember")
    }

    func testMechanicTriggerEventFiresWithTheTargetAndMechanic() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 70, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .selfHeal)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 5, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // one hit crosses the 50% threshold

        XCTAssertEqual(engine.lastMechanicTrigger?.mechanic, .selfHeal)
        XCTAssertEqual(engine.lastMechanicTrigger?.targetID, engine.enemyUnits.first?.id)
    }

    func testShieldMechanicDoesNotFireATriggerEvent() {
        // `.shield` has no distinct "trigger moment" — it's a passive
        // damage-reduction, not a one-shot flourish — so no event should fire.
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 300, attack: 100, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 1000, attack: 0, defense: 0, speed: 1,
                             isBoss: true, mechanic: .shield, shieldCharges: 3)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 15, isBossStage: true)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<15 { engine.tick(dt: 0.1) } // one hit lands, reduced by the shield

        XCTAssertNil(engine.lastMechanicTrigger)
    }

    // MARK: - Active Combat: tap-to-attack

    func testTapAttackTooEarlyDoesNothingButFiresFeedback() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 50, speed: 50)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 500, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)

        // Fresh combatant: attackProgress starts at 0, well below manualTapThreshold.
        let quality = engine.tapAttack(for: hero.id)

        XCTAssertEqual(quality, .tooEarly)
        XCTAssertEqual(engine.lastTapFeedback?.quality, .tooEarly)
        XCTAssertNil(engine.lastHit, "A too-early tap must not deal damage")
    }

    func testTapAttackGoodQualityAppliesBonusDamage() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 50, defense: 0, speed: 70)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // progress = 10 * 0.1 * 70/100 = 0.7 exactly

        let quality = engine.tapAttack(for: hero.id)

        XCTAssertEqual(quality, .good)
        XCTAssertEqual(engine.lastHit?.amount, 60, "50 attack * 1.2 Good multiplier, 0 defense")
    }

    func testTapAttackPerfectQualityAppliesBiggerBonusDamage() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100, attack: 50, defense: 0, speed: 90)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 1000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // progress = 10 * 0.1 * 90/100 = 0.9 exactly

        let quality = engine.tapAttack(for: hero.id)

        XCTAssertEqual(quality, .perfect)
        XCTAssertEqual(engine.lastHit?.amount, 75, "50 attack * 1.5 Perfect multiplier, 0 defense")
    }

    // MARK: - Active Combat: enemy telegraph & Guard

    func testEnemyTelegraphsBeforeLandingAnyDamage() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 0, defense: 0, speed: 1)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 500, attack: 100, defense: 0, speed: 100)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        engine.tick(dt: 1.0) // enemy's progress jumps well past the 0.85 trigger

        XCTAssertTrue(engine.enemyUnits.first?.isTelegraphing ?? false)
        XCTAssertEqual(engine.enemyUnits.first?.telegraphTargetID, hero.id)
        XCTAssertNil(engine.lastHit, "Committing to a wind-up must not deal damage yet")

        engine.tick(dt: 1.0) // the 0.9s wind-up fully elapses

        XCTAssertFalse(engine.enemyUnits.first?.isTelegraphing ?? true)
        XCTAssertNotNil(engine.lastHit)
        XCTAssertEqual(engine.lastHit?.amount, 100)
    }

    func testGuardHalvesATelegraphedHit() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 0, defense: 0, speed: 1)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 500, attack: 100, defense: 0, speed: 100)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        engine.tick(dt: 1.0) // enemy commits to its wind-up against Hero
        XCTAssertTrue(engine.activateGuard(for: hero.id))

        engine.tick(dt: 1.0) // wind-up resolves

        XCTAssertEqual(engine.lastHit?.wasGuarded, true)
        XCTAssertEqual(engine.lastHit?.wasPerfectGuard, false)
        XCTAssertEqual(engine.lastHit?.amount, 50, "Plain Guard halves the hit")
    }

    func testJustGuardNearlyNegatesHitAndStaggersAttacker() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 0, defense: 0, speed: 1)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 500, attack: 100, defense: 0, speed: 100)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        engine.tick(dt: 1.0) // commits: telegraphRemaining = 0.9s
        engine.tick(dt: 0.7) // telegraphRemaining = 0.2s — inside the Just Guard window
        XCTAssertTrue(engine.activateGuard(for: hero.id))

        engine.tick(dt: 0.3) // resolves

        XCTAssertEqual(engine.lastHit?.wasGuarded, true)
        XCTAssertEqual(engine.lastHit?.wasPerfectGuard, true)
        XCTAssertEqual(engine.lastHit?.amount, 20, "Just Guard reduces the hit to a fifth")
        XCTAssertEqual(engine.enemyUnits.first?.stunTicks, 15, "Just Guard staggers the attacker")
    }

    // MARK: - Active Combat: combo meter

    func testComboIncrementsOnConsecutiveHitsWithinTheWindow() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 10, defense: 0, speed: 100)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 100_000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // first auto-fire, at t=1.0s
        XCTAssertEqual(engine.comboCount, 1)

        for _ in 0..<10 { engine.tick(dt: 0.1) } // second auto-fire, 1.0s later — inside the 1.5s window
        XCTAssertEqual(engine.comboCount, 2)

        for _ in 0..<10 { engine.tick(dt: 0.1) } // third auto-fire, another 1.0s later
        XCTAssertEqual(engine.comboCount, 3)
    }

    func testComboResetsAfterAGapLargerThanTheWindow() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 10, defense: 0, speed: 100)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 100_000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // first auto-fire, at t=1.0s
        XCTAssertEqual(engine.comboCount, 1)

        // A single large tick (like the telegraph tests use) advances time by
        // 2.0s and fires the recharged attack exactly once — a loop of small
        // 0.1s ticks would instead complete two full 1.0s auto-fire cycles
        // and legitimately grow the combo instead of testing a real gap.
        engine.tick(dt: 2.0) // second auto-fire, 2.0s later — past the 1.5s window
        XCTAssertEqual(engine.comboCount, 1, "A gap over comboWindow should restart the streak, not extend it")
    }

    func testEnemyHitsDoNotAffectTheComboMeter() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 0, defense: 0, speed: 0)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 500, attack: 50, defense: 0, speed: 100)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        engine.tick(dt: 1.0) // enemy commits its wind-up
        engine.tick(dt: 1.0) // and lands the hit

        XCTAssertNotNil(engine.lastHit)
        XCTAssertEqual(engine.comboCount, 0, "Only player-attributed hits should move the combo meter")
    }

    // MARK: - Active Combat: Chain Burst & Ultimate Finisher

    func testChainBurstFiresOnceComboReachesAMultipleOfFive() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 10, defense: 0, speed: 100)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 100_000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<40 { engine.tick(dt: 0.1) } // four auto-fires, 1.0s apart — combo = 4
        XCTAssertEqual(engine.comboCount, 4)
        XCTAssertNil(engine.lastChainBurst, "No Chain Burst before the 5th consecutive hit")

        for _ in 0..<10 { engine.tick(dt: 0.1) } // the 5th auto-fire
        XCTAssertNotNil(engine.lastChainBurst, "A Chain Burst should fire the instant combo crosses a multiple of 5")
        XCTAssertEqual(engine.lastChainBurst?.casterID, hero.id, "The lone Dreamkeeper is the only possible Chain Burst caster")
    }

    func testUltimateIsNotAFinisherBelowComboThreshold() {
        let ultimate = UltimateSkill(name: "Blast", description: "", damageMultiplier: 2, attacksToCharge: 1)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 10, defense: 0, speed: 100, ultimate: ultimate)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 100_000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // one auto-fire charges the ultimate; combo is only 1
        XCTAssertTrue(engine.activateUltimate(for: hero.id))
        XCTAssertEqual(engine.lastUltimate?.isFinisher, false)
    }

    func testUltimateBecomesAFinisherAtComboTenPlus() {
        let ultimate = UltimateSkill(name: "Blast", description: "", damageMultiplier: 2, attacksToCharge: 1)
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 500, attack: 10, defense: 0, speed: 100, ultimate: ultimate)
        let enemy = makeUnit(name: "Enemy", isPlayer: false, hp: 100_000, attack: 0, defense: 0, speed: 0)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)
        engine.varianceProvider = { 1.0 }

        // ~10 auto-fires a second apart, plus the Chain Bursts they trigger
        // along the way (each of which is itself a player-attributed hit),
        // push the combo comfortably past the Finisher threshold.
        for _ in 0..<100 { engine.tick(dt: 0.1) }
        XCTAssertGreaterThanOrEqual(engine.comboCount, BattleEngine.comboFinisherThreshold)

        XCTAssertTrue(engine.activateUltimate(for: hero.id))
        XCTAssertEqual(engine.lastUltimate?.isFinisher, true)
    }

    // MARK: - World Boss: round limit & timeout

    func testRoundLimitResolvesAsTimeoutWhenBothSidesSurvive() {
        // High defense on both sides means every hit lands at the `max(1, ...)`
        // damage floor — neither side can die within the tick budget, so only
        // `roundLimit` being reached can end the fight.
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100_000, attack: 5, defense: 1000, speed: 60)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 1_000_000, attack: 10, defense: 1000, speed: 60)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 1, isBossStage: true, roundLimit: 3)
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 5000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }

        XCTAssertEqual(engine.outcome, .timeout)
        XCTAssertEqual(engine.roundsElapsed, 3)
    }

    func testVictoryStillWinsWhenAchievedBeforeRoundLimit() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 5000, speed: 100)
        let boss = makeUnit(name: "Weak Boss", isPlayer: false, hp: 30, attack: 0, speed: 20)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 1, isBossStage: true, roundLimit: 50)
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }

        XCTAssertEqual(engine.outcome, .victory, "A real kill should still win outright, not wait for roundLimit")
    }

    func testDefeatStillLosesBeforeRoundLimitIsReached() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 10, attack: 0, defense: 0, speed: 20)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 100_000, attack: 500, defense: 0, speed: 80)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 1, isBossStage: true, roundLimit: 50)
        engine.varianceProvider = { 1.0 }

        var iterations = 0
        while engine.outcome == nil && iterations < 2000 {
            engine.tick(dt: 0.1)
            iterations += 1
        }

        XCTAssertEqual(engine.outcome, .defeat)
    }

    func testTotalDamageToEnemyAccumulatesAcrossMultipleHits() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 100_000, attack: 20, defense: 0, speed: 100)
        let boss = makeUnit(name: "Boss", isPlayer: false, hp: 1_000_000, attack: 0, defense: 0, speed: 1)
        let engine = BattleEngine(playerUnits: [hero], enemy: boss, stage: 1, isBossStage: true, roundLimit: 50)
        engine.varianceProvider = { 1.0 }

        for _ in 0..<10 { engine.tick(dt: 0.1) } // one hero attack lands
        let afterOneHit = engine.totalDamageToEnemy
        XCTAssertGreaterThan(afterOneHit, 0)

        for _ in 0..<10 { engine.tick(dt: 0.1) } // second hero attack lands
        XCTAssertGreaterThan(engine.totalDamageToEnemy, afterOneHit)
    }

    func testRoundLimitIsNilOutsideWorldBossFights() {
        let hero = makeUnit(name: "Hero", isPlayer: true, hp: 200, attack: 40, speed: 80)
        let enemy = makeUnit(name: "Weakling", isPlayer: false, hp: 30, attack: 2, speed: 20)
        let engine = BattleEngine(playerUnits: [hero], enemy: enemy, stage: 1, isBossStage: false)

        XCTAssertNil(engine.roundLimit)
    }
}
