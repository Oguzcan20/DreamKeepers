import Foundation

/// Passive resource accrual for the Gold Fountain (gold) and Training Garden
/// (EXP) buildings. Both accrue at a flat per-minute rate up to a cap so
/// players are rewarded for checking in without needing to stay online.
enum OfflineRewards {
    static let maxAccrualSeconds: TimeInterval = 8 * 3600
    static let goldPerMinute = 6
    static let expPerMinute = 4

    static func accruedSeconds(since lastCollected: Date, now: Date = Date()) -> TimeInterval {
        max(0, min(now.timeIntervalSince(lastCollected), maxAccrualSeconds))
    }

    static func pendingGold(since lastCollected: Date, now: Date = Date()) -> Int {
        Int(accruedSeconds(since: lastCollected, now: now) / 60 * Double(goldPerMinute))
    }

    static func pendingExp(since lastCollected: Date, now: Date = Date()) -> Int {
        Int(accruedSeconds(since: lastCollected, now: now) / 60 * Double(expPerMinute))
    }
}
