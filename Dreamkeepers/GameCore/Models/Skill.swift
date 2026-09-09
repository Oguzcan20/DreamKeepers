import Foundation

/// A Dreamkeeper's manually-triggered Ultimate. Basic attacks are automatic and
/// not modeled as a Skill — see BattleEngine.
struct UltimateSkill: Codable, Equatable {
    var name: String
    var description: String
    /// Multiplier applied to the unit's attack stat when the ultimate lands.
    var damageMultiplier: Double
    /// Basic attacks required to fill the energy meter before the ultimate is ready.
    var attacksToCharge: Int
}

/// An always-on trait applied at battle start (kept simple for the MVP: a flat
/// stat modifier rather than a full effect system).
struct PassiveTrait: Codable, Equatable {
    var name: String
    var description: String
    var statBonus: Stats
    /// Fraction of max HP to revive at, once per battle, the instant this
    /// combatant would otherwise fall. `nil` for every Dreamkeeper without
    /// this passive (Igo's Gezeitenwache is the only user today).
    var reviveHPFraction: Double? = nil
    /// Extra attack multiplier at 0 HP, scaling linearly down to 0 at full
    /// HP. `nil` for every Dreamkeeper without this passive (Ames' Feuertaufe
    /// is the only user today).
    var lowHPAttackBonus: Double? = nil
}

/// A Dreamkeeper's manually-triggered mid-tier skill — quicker and weaker than
/// the Ultimate, on a short real-time cooldown instead of an attack-count
/// energy meter, so it reads as a distinct tactical button. Player units only.
/// `effectMultiplier` is applied to the caster's attack stat and is
/// reinterpreted per role exactly like `UltimateSkill.damageMultiplier` is
/// (see BattleEngine.activateSkill): a strike multiplier for damage/tank/
/// control, a heal multiplier for healer, an attack-growth factor for support.
struct ActiveSkill: Codable, Equatable {
    var name: String
    var description: String
    var effectMultiplier: Double
    var cooldownSeconds: Double
}
