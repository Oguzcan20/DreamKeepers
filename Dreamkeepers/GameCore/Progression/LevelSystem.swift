import Foundation

/// Pure, testable EXP/leveling rules. Kept independent of persistence and UI
/// so it can be unit tested and reused for both Dreamkeepers and the Player.
enum LevelSystem {
    static let maxLevel = 50

    /// Dream EXP required to advance from `level` to `level + 1`.
    static func expToNextLevel(from level: Int) -> Int {
        guard level < maxLevel else { return .max }
        return 20 + level * 15
    }

    struct LevelUpResult: Equatable {
        var finalLevel: Int
        var finalExp: Int
        var levelsGained: Int
    }

    /// Applies gained EXP, resolving as many level-ups as the EXP allows.
    static func applyExp(_ gained: Int, level: Int, exp: Int) -> LevelUpResult {
        var level = level
        var exp = exp + gained
        var levelsGained = 0

        while level < maxLevel {
            let required = expToNextLevel(from: level)
            guard exp >= required else { break }
            exp -= required
            level += 1
            levelsGained += 1
        }

        if level >= maxLevel {
            exp = 0
        }

        return LevelUpResult(finalLevel: level, finalExp: exp, levelsGained: levelsGained)
    }
}
