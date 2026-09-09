import Foundation

/// One-off milestone context that isn't derivable from persistent save
/// state alone — currently just "did the battle just resolved end with the
/// party at full HP." Extend this rather than adding one-off flags to
/// `GameSave` for events that only matter for a single instant.
struct AchievementContext {
    var isPerfectClear: Bool = false
}

/// A single unlockable milestone: static content plus the predicate that
/// decides whether it's currently true against live game state.
struct Achievement: Identifiable, Equatable {
    static func == (lhs: Achievement, rhs: Achievement) -> Bool { lhs.id == rhs.id }

    let id: String
    let title: String
    let detail: String
    let icon: String
    let predicate: (GameState, AchievementContext) -> Bool
}

/// The full catalog of milestones plus the evaluation pass `GameState` runs
/// after any mutation that could complete one. Deliberately simple: no
/// tiers or points, just a title/detail/icon worth a celebration popup the
/// instant its predicate first turns true.
enum AchievementSystem {
    // Read-only static data whose only non-Sendable part is each
    // achievement's predicate closure (it takes `GameState`, a class) — in
    // practice this is only ever read synchronously from `GameState`'s own
    // methods, all called on the main actor, so this is safe.
    nonisolated(unsafe) static let all: [Achievement] = [
        Achievement(
            id: "first_summon", title: "First Summon",
            detail: "Summon your first Dreamkeeper.", icon: "sparkles",
            predicate: { state, _ in state.roster.count >= 2 }
        ),
        Achievement(
            id: "first_legendary", title: "Legendary!",
            detail: "Recruit a Legendary Dreamkeeper.", icon: "star.circle.fill",
            predicate: { state, _ in state.roster.contains { state.definition(for: $0)?.rarity == .legendary } }
        ),
        Achievement(
            id: "collector_5", title: "Growing Collection",
            detail: "Own 5 different Dreamkeepers.", icon: "person.3.fill",
            predicate: { state, _ in Set(state.roster.map(\.definitionID)).count >= 5 }
        ),
        Achievement(
            id: "collector_10", title: "Dream Team",
            detail: "Own 10 different Dreamkeepers.", icon: "person.3.sequence.fill",
            predicate: { state, _ in Set(state.roster.map(\.definitionID)).count >= 10 }
        ),
        Achievement(
            id: "first_boss", title: "Boss Slayer",
            detail: "Defeat your first Boss.", icon: "flame.fill",
            predicate: { state, _ in state.save.currentStage > World.stagesPerWorld }
        ),
        Achievement(
            id: "star_up", title: "Star Power",
            detail: "Fuse a Dreamkeeper to raise its stars.", icon: "star.fill",
            predicate: { state, _ in state.roster.contains { $0.stars >= 1 } }
        ),
        Achievement(
            id: "max_stars", title: "Fully Ascended",
            detail: "Raise a Dreamkeeper to max stars.", icon: "star.circle.fill",
            predicate: { state, _ in state.roster.contains { $0.stars >= StarFusionSystem.maxStars } }
        ),
        Achievement(
            id: "full_team", title: "Squad Goals",
            detail: "Deploy a full team of \(Team.maxSize).", icon: "shield.fill",
            predicate: { state, _ in state.deployedTeam.count >= Team.maxSize }
        ),
        Achievement(
            id: "perfect_clear", title: "Untouchable",
            detail: "Win a battle without taking damage.", icon: "shield.checkered",
            predicate: { _, context in context.isPerfectClear }
        ),
        Achievement(
            id: "account_level_10", title: "Rising Dreamer",
            detail: "Reach Account Level 10.", icon: "arrow.up.circle.fill",
            predicate: { state, _ in state.save.playerLevel >= 10 }
        ),
        Achievement(
            id: "gold_hoarder", title: "Gold Hoarder",
            detail: "Hold 5,000 Gold at once.", icon: "circle.hexagongrid.fill",
            predicate: { state, _ in state.save.gold >= 5_000 }
        ),
        Achievement(
            id: "monster_hunter", title: "Monster Hunter",
            detail: "Discover 10 different monsters.", icon: "eye.fill",
            predicate: { state, _ in state.save.discoveredMonsters.count >= 10 }
        ),
        Achievement(
            id: "week_streak", title: "Dedicated Dreamer",
            detail: "Claim all 7 days of a Login Streak.", icon: "calendar.badge.checkmark",
            predicate: { state, _ in state.save.loginStreakDay >= LoginRewardSystem.cycleLength }
        ),
    ]
}
