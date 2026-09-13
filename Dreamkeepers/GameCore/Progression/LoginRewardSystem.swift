import Foundation

/// One day's reward in the login-streak calendar.
struct LoginRewardDay: Identifiable, Equatable {
    var id: Int { day }
    var day: Int
    var gold: Int
    var gems: Int
    /// Energy granted alongside gold/gems — every day gives at least some,
    /// so logging in is always a meaningful top-up even on a gold-only day.
    var energy: Int = 0
    /// Free Dreamkeeper/Equipment Summoning tickets granted alongside
    /// gold/gems/energy — see `GameSave.monsterSummonTickets`/
    /// `.equipmentSummonTickets`. Deliberately spread early in the cycle
    /// (not saved for Day 7 alone) so a new player has a reason to summon
    /// again within their first week, not just once at the start.
    var monsterTickets: Int = 0
    var equipmentTickets: Int = 0
    var icon: String
}

/// The fixed 7-day login-streak calendar. Claiming is once per calendar
/// day (see `GameState.claimLoginReward`); missing a day resets back to
/// Day 1 rather than losing progress mid-cycle, so a lapsed player always
/// has the same easy on-ramp back in as a brand new one.
enum LoginRewardSystem {
    static let cycleLength = 7

    static let days: [LoginRewardDay] = [
        LoginRewardDay(day: 1, gold: 50, gems: 0, energy: 15, icon: "circle.hexagongrid.fill"),
        LoginRewardDay(day: 2, gold: 80, gems: 0, energy: 15, icon: "circle.hexagongrid.fill"),
        LoginRewardDay(day: 3, gold: 0, gems: 10, energy: 20, monsterTickets: 1, icon: "sparkles"),
        LoginRewardDay(day: 4, gold: 120, gems: 0, energy: 15, icon: "circle.hexagongrid.fill"),
        LoginRewardDay(day: 5, gold: 0, gems: 15, energy: 20, equipmentTickets: 1, icon: "sparkles"),
        LoginRewardDay(day: 6, gold: 150, gems: 0, energy: 15, icon: "circle.hexagongrid.fill"),
        LoginRewardDay(day: 7, gold: 200, gems: 40, energy: 40, monsterTickets: 1, equipmentTickets: 1, icon: "star.circle.fill")
    ]

    static func reward(forDay day: Int) -> LoginRewardDay? {
        days.first { $0.day == day }
    }
}
