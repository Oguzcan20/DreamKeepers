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
