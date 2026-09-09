import Foundation

/// Procedural single-enemy encounters, themed by the stage's World. Hand-
/// authored encounter tables can replace this later without touching
/// BattleEngine — both just produce a `Combatant`.
enum EnemyFactory {
    /// Modest stat bump for rarer regular monsters, same philosophy as
    /// `EquipmentFactory.rollRarity`'s multiplier — flavor becomes a real,
    /// if small, mechanical difference rather than pure cosmetics.
    private static func rarityMultiplier(_ rarity: Rarity) -> Double {
        switch rarity {
        case .common: return 1.0
        case .uncommon: return 1.08
        case .rare: return 1.18
        case .epic: return 1.3
        case .legendary: return 1.45
        case .mythic: return 1.6
        case .exclusive: return 1.6 // Enemies never actually roll .exclusive; kept for switch exhaustiveness.
        }
    }

    static func enemy(forStage stage: Int) -> Combatant {
        let world = WorldCatalog.world(forStage: stage)
        let isBoss = stage % World.stagesPerWorld == 0
        // Linear per-stage growth stacked with a per-world tier multiplier,
        // so difficulty jumps feel tiered (spec section 7) instead of only
        // smoothly linear across all 50 stages.
        let scale = (1.0 + Double(stage - 1) * 0.22) * world.difficultyMultiplier
        let bossScale = isBoss ? 1.6 : 1.0

        let name: String
        let symbol: String
        let role: Role
        let element: Element
        let ultimate: UltimateSkill?
        let mechanic: BossMechanic?
        let rarityScale: Double

        if isBoss {
            let boss = MonsterCatalog.boss(forWorld: world.id)
            name = world.bossName
            symbol = boss.symbol
            role = .tank
            element = world.elementBias[stage % world.elementBias.count]
            ultimate = boss.ultimate
            mechanic = boss.mechanic
            rarityScale = 1.0
        } else {
            let monster = MonsterCatalog.regularMonster(forWorld: world.id, stage: stage)
            name = monster.name
            symbol = monster.symbol
            role = monster.role
            element = world.elementBias[stage % world.elementBias.count]
            ultimate = nil
            mechanic = nil
            rarityScale = rarityMultiplier(monster.rarity)
        }

        let totalScale = scale * bossScale * rarityScale
        return Combatant(
            id: UUID(),
            name: name,
            element: element,
            role: role,
            isPlayer: false,
            isBoss: isBoss,
            maxHP: (60 * totalScale).rounded(),
            currentHP: (60 * totalScale).rounded(),
            attack: (11 * totalScale).rounded(),
            defense: (5 * totalScale).rounded(),
            speed: (45 + Double(stage)).rounded(),
            ultimate: ultimate,
            symbol: symbol,
            mechanic: mechanic,
            shieldCharges: mechanic == .shield ? 3 : 0
        )
    }
}
