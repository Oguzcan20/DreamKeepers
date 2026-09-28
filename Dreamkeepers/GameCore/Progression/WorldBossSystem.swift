import Foundation

/// The weekly World Boss event: a single shared-stat boss every player fights
/// in their own solo `BattleEngine` instance (there's no server, so there's
/// no single shared boss HP pool — see `GameState`'s World Boss section for
/// why a Firestore leaderboard, not a live shared fight, is what ties players
/// together here). Live Friday 19:00 UTC through Sunday 19:00 UTC; each
/// player gets `attacksPerWeek` tries, damage from every try adds up, and the
/// week's ranking pays out once the window closes.
///
/// Deliberately UTC-fixed rather than using the device's own locale/calendar
/// (`Calendar.current`'s week can start on Sunday depending on region — see
/// `GameState.ensureWeeklyMissionsCurrent`, which inherits that quirk
/// harmlessly since its rewards are personal). A cross-player leaderboard
/// can't tolerate that skew: two players in different regions must see the
/// exact same window and the exact same week's boss.
enum WorldBossSystem {
    /// Shared with `WorldBossView`/`WorldBossResultView` so `MonsterArt`
    /// lookups (and `bossCombatant()` below) always agree on the exact name.
    static let bossName = "Voidmaw, the Devouring Dream"

    static let attacksPerWeek = 3
    /// One "round" is one boss attack cycle (see `BattleEngine.roundsElapsed`).
    static let roundLimit = 50

    private static let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = 2 // Monday, independent of device locale — only used to derive a stable ISO week number.
        cal.minimumDaysInFirstWeek = 4 // ISO-8601 week rule, for a stable weekOfYear.
        return cal
    }()

    /// Friday 19:00 UTC that starts the fight window containing `date` — the
    /// stable key every player's window/weekID is computed from, whether
    /// `date` falls inside the live Friday-Sunday window itself or in the
    /// dormant days afterward (so a player returning after the window closed
    /// to claim a reward still resolves to the same cycle they fought in).
    static func weekStart(for date: Date) -> Date {
        let mondayThisWeek = utc.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let fridayThisWeek = utc.date(byAdding: .day, value: 4, to: mondayThisWeek) ?? mondayThisWeek
        let friday1900ThisWeek = utc.date(byAdding: .hour, value: 19, to: fridayThisWeek) ?? fridayThisWeek
        if date >= friday1900ThisWeek { return friday1900ThisWeek }
        // Before this week's Friday 19:00 — still in last week's cycle.
        let mondayLastWeek = utc.date(byAdding: .day, value: -7, to: mondayThisWeek) ?? mondayThisWeek
        let fridayLastWeek = utc.date(byAdding: .day, value: 4, to: mondayLastWeek) ?? mondayLastWeek
        return utc.date(byAdding: .hour, value: 19, to: fridayLastWeek) ?? fridayLastWeek
    }

    /// A stable, human-inspectable identifier for the week containing `date`
    /// (e.g. `"2026-W39"`) — the Firestore document path segment for that
    /// week's leaderboard and the `GameSave.worldBossClaimedWeeks` dedupe key.
    static func weekID(for date: Date) -> String {
        let start = weekStart(for: date)
        let year = utc.component(.yearForWeekOfYear, from: start)
        let week = utc.component(.weekOfYear, from: start)
        return String(format: "%04d-W%02d", year, week)
    }

    /// The fight window for the week containing `date`: Friday 19:00 UTC
    /// (announcement/appearance) through Sunday 19:00 UTC (attacks close).
    static func window(for date: Date) -> (start: Date, end: Date) {
        let start = weekStart(for: date)
        let end = utc.date(byAdding: .day, value: 2, to: start) ?? start
        return (start, end)
    }

    static func isActive(at date: Date = Date()) -> Bool {
        let w = window(for: date)
        return date >= w.start && date < w.end
    }

    /// The boss every player fights this week — identical stats for
    /// everyone, so the leaderboard measures skill/roster strength, not luck.
    /// First-pass balance (see doc comment on the constants below); intended
    /// to be retuned from real playtesting, not treated as final.
    static func bossCombatant() -> Combatant {
        Combatant(
            id: UUID(),
            name: bossName,
            element: .astral,
            role: .tank,
            isPlayer: false,
            isBoss: true,
            maxHP: bossMaxHP,
            currentHP: bossMaxHP,
            attack: bossAttack,
            defense: bossDefense,
            speed: bossSpeed,
            ultimate: nil,
            symbol: "eye.trianglebadge.exclamationmark.fill",
            mechanic: .enrage
        )
    }

    /// Tuned so a level-25, 2-star, unequipped four-member team (the "medium
    /// team" the spec calls for) comfortably survives all `roundLimit` rounds
    /// under `BattleEngine`'s real damage formula
    /// (`attack - defense * 0.5`, focus-fire on the lowest-HP ally), while a
    /// fresh level-1 roster still lands real hits and gets a genuine handful
    /// of rounds rather than an instant, meaningless wipe.
    static let bossMaxHP: Double = 50_000
    static let bossAttack: Double = 36
    static let bossDefense: Double = 22
    static let bossSpeed: Double = 52

    // MARK: - Rewards

    struct Reward: Equatable {
        var gold: Int
        var gems: Int
    }

    /// `nil` for rank 201 and beyond — per spec, nothing is paid out past
    /// rank 200. Ranks 1 and 2-10 each get their own individually-sized
    /// reward (rank 1 the single biggest prize); 11-50/51-100/101-200 are
    /// flat brackets, each smaller than the last.
    static func reward(forRank rank: Int) -> Reward? {
        switch rank {
        case 1:
            return Reward(gold: 150_000, gems: 3_000)
        case 2...10:
            // Linear step down from rank 2 (2000 gems/100k gold) to rank 10
            // (400 gems/20k gold).
            let steps = rank - 2
            let gold = 100_000 - steps * 10_000
            let gems = 2_000 - steps * 200
            return Reward(gold: gold, gems: gems)
        case 11...50:
            return Reward(gold: 15_000, gems: 150)
        case 51...100:
            return Reward(gold: 8_000, gems: 75)
        case 101...200:
            return Reward(gold: 3_000, gems: 30)
        default:
            return nil
        }
    }
}
