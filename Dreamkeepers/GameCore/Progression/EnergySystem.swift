import Foundation

/// Stamina gate on how many stages can be fought or swept back-to-back.
/// Regenerates passively over real time (`GameState.refreshEnergy`), tops
/// up from missions/login rewards, or can be bought outright with Dream
/// Gems a limited number of times per day. Pure, testable math — GameState
/// owns the persisted clock and gem spend.
enum EnergySystem {
    static let maxEnergy = 100

    /// Cost per stage attempt — a normal fight and a Sweep pay the same for
    /// a given stage, since both grant identical rewards for it. Boss
    /// stages (last stage of a world) cost double a normal stage.
    static let normalStageCost = 5
    static let bossStageCost = 10

    /// Convenience for call sites that already know whether the stage is a
    /// boss stage (`stage % World.stagesPerWorld == 0`).
    static func stageCost(isBoss: Bool) -> Int {
        isBoss ? bossStageCost : normalStageCost
    }

    /// Seconds for one point of Energy to regenerate. 100 max / 5 cost
    /// means a full bar covers 20 normal stages (or 10 boss stages).
    static let regenIntervalSeconds: TimeInterval = 180

    static let energyPerRefill = 30
    static let maxRefillsPerDay = 5

    /// Gem cost climbs with each refill already bought today (resets at
    /// midnight with `GameSave.energyRefillDay`) — keeps the first top-up
    /// cheap while discouraging buying the whole day's energy in one go.
    static func refillGemCost(refillsUsedToday: Int) -> Int {
        20 + refillsUsedToday * 10
    }
}
