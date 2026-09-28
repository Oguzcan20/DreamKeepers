import XCTest
@testable import Dreamkeepers

final class WorldBossSystemTests: XCTestCase {
    private static let utc: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        var comps = DateComponents()
        comps.year = year; comps.month = month; comps.day = day; comps.hour = hour; comps.minute = minute
        return Self.utc.date(from: comps)!
    }

    // 2026-09-25 is a Friday (per today's date in this session).

    func testWindowIsFriday1900ThroughSunday1900() {
        // Saturday, inside the live window — Friday noon that same week
        // still belongs to the *previous* (already-closed) cycle, since the
        // boss hasn't appeared yet at that moment (see the "just before
        // Friday open" test below).
        let w = WorldBossSystem.window(for: date(2026, 9, 26, 12))
        XCTAssertEqual(w.start, date(2026, 9, 25, 19))
        XCTAssertEqual(w.end, date(2026, 9, 27, 19))
    }

    func testIsActiveJustAfterFridayOpen() {
        XCTAssertTrue(WorldBossSystem.isActive(at: date(2026, 9, 25, 19, 1)))
    }

    func testIsActiveJustBeforeFridayOpenIsFalse() {
        XCTAssertFalse(WorldBossSystem.isActive(at: date(2026, 9, 25, 18, 59)))
    }

    func testIsActiveDuringSaturdayIsTrue() {
        XCTAssertTrue(WorldBossSystem.isActive(at: date(2026, 9, 26, 12)))
    }

    func testIsActiveExactlyAtSundayCloseIsFalse() {
        // `window(for:).end` is exclusive.
        XCTAssertFalse(WorldBossSystem.isActive(at: date(2026, 9, 27, 19)))
    }

    func testIsActiveJustBeforeSundayCloseIsTrue() {
        XCTAssertTrue(WorldBossSystem.isActive(at: date(2026, 9, 27, 18, 59)))
    }

    func testWeekStartStaysStableThroughTheDormantDaysAfterClose() {
        // A player returning Wednesday (well after Sunday 19:00 close) to
        // claim a reward must still resolve to the same cycle they fought in.
        let duringWindow = WorldBossSystem.weekStart(for: date(2026, 9, 26, 10))
        let afterClose = WorldBossSystem.weekStart(for: date(2026, 10, 1, 10))
        XCTAssertEqual(duringWindow, afterClose)
    }

    func testWeekStartAdvancesOnceTheNextFridayArrives() {
        let thisWeek = WorldBossSystem.weekStart(for: date(2026, 9, 26, 10))
        let nextWeek = WorldBossSystem.weekStart(for: date(2026, 10, 2, 20))
        XCTAssertNotEqual(thisWeek, nextWeek)
        XCTAssertEqual(nextWeek, date(2026, 10, 2, 19))
    }

    func testWeekIDIsStableAcrossTheSameCycle() {
        let idDuring = WorldBossSystem.weekID(for: date(2026, 9, 26, 10))
        let idAfter = WorldBossSystem.weekID(for: date(2026, 9, 29, 10))
        XCTAssertEqual(idDuring, idAfter)
    }

    // MARK: - Reward tiers

    func testRewardRankOneIsTheLargestPrize() {
        let reward = WorldBossSystem.reward(forRank: 1)
        XCTAssertEqual(reward, WorldBossSystem.Reward(gold: 150_000, gems: 3_000))
    }

    func testRewardStepsDownLinearlyFromRankTwoToTen() {
        XCTAssertEqual(WorldBossSystem.reward(forRank: 2), WorldBossSystem.Reward(gold: 100_000, gems: 2_000))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 10), WorldBossSystem.Reward(gold: 20_000, gems: 400))
    }

    func testRewardBracketBoundaries() {
        XCTAssertEqual(WorldBossSystem.reward(forRank: 11), WorldBossSystem.Reward(gold: 15_000, gems: 150))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 50), WorldBossSystem.Reward(gold: 15_000, gems: 150))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 51), WorldBossSystem.Reward(gold: 8_000, gems: 75))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 100), WorldBossSystem.Reward(gold: 8_000, gems: 75))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 101), WorldBossSystem.Reward(gold: 3_000, gems: 30))
        XCTAssertEqual(WorldBossSystem.reward(forRank: 200), WorldBossSystem.Reward(gold: 3_000, gems: 30))
    }

    func testRewardIsNilPastRankTwoHundred() {
        XCTAssertNil(WorldBossSystem.reward(forRank: 201))
        XCTAssertNil(WorldBossSystem.reward(forRank: 10_000))
    }

    // MARK: - Boss combatant

    func testBossCombatantIsSharedAndNotAPlayer() {
        let boss = WorldBossSystem.bossCombatant()
        XCTAssertFalse(boss.isPlayer)
        XCTAssertTrue(boss.isBoss)
        XCTAssertEqual(boss.maxHP, WorldBossSystem.bossMaxHP)
    }
}
