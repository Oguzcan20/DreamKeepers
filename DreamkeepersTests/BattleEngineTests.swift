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
}
