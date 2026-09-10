import Foundation

/// Loot granted for clearing a stage. Boss stages pay out more.
struct BattleRewards: Equatable {
    var gold: Int
    var expPerSurvivor: Int
    /// Account (player) EXP — smaller than Dreamkeeper EXP since it only
    /// needs to move a single, much slower-growing level track.
    var accountExp: Int
}

enum RewardTable {
    static func rewards(forStage stage: Int, isBoss: Bool) -> BattleRewards {
        let base = 30 + stage * 8
        let multiplier = isBoss ? 2.2 : 1.0
        return BattleRewards(
            gold: Int((Double(base) * multiplier).rounded()),
            expPerSurvivor: Int((Double(18 + stage * 5) * multiplier).rounded()),
            accountExp: Int((Double(8 + stage * 3) * multiplier).rounded())
        )
    }
}

/// Dream Gems granted the first time a `World`'s boss is cleared (see
/// `GameState.applyBattleResult`'s `wasFrontierClear` guard — replaying an
/// already-cleared boss never re-grants this, same rule as the recruit
/// grant). Every 5th completed World pays a bigger one-time bonus instead of
/// the standard amount: worlds 1-4 pay 50, world 5 pays 100, worlds 6-9 pay
/// 50 again, world 10 pays 100, and so on — never additive with the
/// standard amount, just a bigger flat payout on the milestone world.
enum WorldClearRewardSystem {
    static let standardGems = 50
    static let milestoneGems = 100
    static let milestoneInterval = 5

    static func gems(forCompletedWorld worldNumber: Int) -> Int {
        worldNumber % milestoneInterval == 0 ? milestoneGems : standardGems
    }
}
