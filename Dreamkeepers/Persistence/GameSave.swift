import Foundation

/// Everything that survives an app relaunch. Deliberately flat and Codable
/// so it can move to a cloud-synced store later without changing callers —
/// only LocalSaveStore's implementation would change.
struct GameSave: Codable, Equatable {
    var playerLevel: Int
    var playerExp: Int
    var gold: Int
    var dreamGems: Int
    var roster: [DreamkeeperInstance]
    var teams: [Team]
    var activeTeamID: UUID
    var inventory: [EquipmentItem]
    var currentStage: Int
    var lastGoldCollectedAt: Date
    var lastTrainingCollectedAt: Date
    var dailyMissionDay: Date
    var dailyMissionProgress: [String: Int]
    var claimedMissionIDs: Set<String>
    /// Today's randomly-drawn subset of `DailyMissions.rotatingPool`
    /// (`MissionID.rawValue`s), redrawn by `GameState.ensureMissionsCurrent`
    /// whenever `dailyMissionDay` rolls over — the free-tier board isn't the
    /// same fixed 7 missions every day. Empty means "not drawn yet", which
    /// `ensureMissionsCurrent` also treats as needing a (re)draw, so a save
    /// from before this field existed backfills it on next load instead of
    /// showing zero missions until the following day.
    var dailyMissionSelectedIDs: [String]
    var weeklyMissionWeek: Date
    var weeklyMissionProgress: [String: Int]
    var claimedWeeklyMissionIDs: Set<String>
    var purchasedOneTimeOfferIDs: Set<String>
    var hapticsEnabled: Bool
    var soundEnabled: Bool
    var discoveredMonsters: Set<String>
    var battlePassXP: Int
    var battlePassPremiumUnlocked: Bool
    var claimedBattlePassRewardIDs: Set<String>
    /// "de", "en", or nil to follow the device's system language. Spec
    /// follow-up: an explicit in-app override, not just system Settings.
    var preferredLanguage: String?
    /// Local (on-device) reminders for the two offline buildings capping out
    /// and the daily mission reset. Off by default until the player opts in
    /// via Settings — enabling it is what actually requests OS permission.
    var notificationsEnabled: Bool
    /// Whether the first-launch walkthrough (Summon / Fusion / Team /
    /// Campaign) has already been shown. `newGame()` starts this at `false`;
    /// saves from before this flag existed default to `true` in `init(from:)`
    /// so it never retroactively interrupts an existing player.
    var hasSeenOnboarding: Bool
    /// True once the player has locked in the starter Olf's element (or
    /// unlocked Ultimate Olf via the secret hold) — see
    /// `GameState.needsStarterOlfChoice`/`chooseStarterOlf(element:)`.
    /// Deliberately a separate flag rather than inferring "already chosen"
    /// from the roster's `definitionID`: `DreamkeeperCatalog.olfDefinitionID(for: .ember)`
    /// happens to equal `DreamkeeperCatalog.starterOlfDefaultID` itself, so a
    /// player who picks Ember would otherwise leave the placeholder id
    /// unchanged and get the choice screen again on every visit to Dream
    /// Haven. `newGame()` starts this at `false`; saves from before this
    /// flag existed default to `true` in `init(from:)` so it never
    /// retroactively interrupts an existing player.
    var hasChosenStarterElement: Bool
    /// Milestone IDs already unlocked (and already shown to the player) —
    /// see `AchievementSystem`. Persisted so a popup never fires twice.
    var unlockedAchievementIDs: Set<String>
    /// Which day (1...`LoginRewardSystem.cycleLength`) of the login-streak
    /// calendar was most recently claimed. 0 means never claimed.
    var loginStreakDay: Int
    /// Calendar date of that claim, used to tell "continues the streak"
    /// (yesterday), "already claimed" (today), and "streak lapsed" (older)
    /// apart. `.distantPast` until the first ever claim.
    var lastLoginRewardClaimDate: Date
    /// One-time real-money purchase (see `ShopItemKind.vip`). Removes the
    /// rewarded-ad prompt permanently — nothing else currently checks this,
    /// but it's the natural place to gate any future VIP-only perk too.
    var isVIP: Bool
    /// Timestamp of the most recent rewarded-ad watch — informational only
    /// (not used for gating; see `rewardedAdWatchDay`/`rewardedAdWatchCount`).
    var lastRewardedAdClaimedAt: Date
    /// Calendar day `rewardedAdWatchCount` is counting against — see
    /// `GameState.maxRewardedAdsPerDay`. Resets both once the stored day no
    /// longer matches today, same pattern as `dailyMissionDay`.
    var rewardedAdWatchDay: Date
    var rewardedAdWatchCount: Int
    /// Stages cleared since the last automatic interstitial — see
    /// `GameState.stagesPerInterstitial`. Reset (not incremented) by
    /// anything else touching `currentStage`.
    var stagesSinceLastInterstitial: Int
    /// Pacing floor so an interstitial can never fire twice within
    /// `GameState.minSecondsBetweenInterstitials`, however fast stages
    /// clear. `.distantPast` means never shown.
    var lastInterstitialShownAt: Date
    /// Pulls since the last Epic+ / Legendary+ result — shared across both
    /// Dreamkeeper and Equipment Summoning (same pool as `SummonSystem.rarityOdds`)
    /// so the pity clock is one dial, not two. See `GameState.nextPitySummonRarity`.
    var pullsSinceEpicSummon: Int
    var pullsSinceLegendarySummon: Int
    /// True once the player has used their very first 10x multi-summon (of
    /// either type) — that pull is upgraded so it can't roll an all-Common
    /// result. One-time, shared across Dreamkeeper and Equipment Summoning.
    var hasUsedBeginnerMultiSummon: Bool
    /// 1.0 or 2.0 — persisted battle tick-rate multiplier set via the
    /// in-battle speed toggle.
    var battleSpeedMultiplier: Double
    /// Persisted state of the in-battle Auto-Battle toggle: fires each
    /// deployed Dreamkeeper's Active Skill/Ultimate the instant it's ready.
    var autoBattleEnabled: Bool
    /// Current stamina — spent per stage attempt (fight or Sweep alike),
    /// regenerated over time. See `EnergySystem` / `GameState.refreshEnergy`.
    var energy: Int
    /// Clock baseline the passive regen ticks forward from. Pinned to "now"
    /// whenever `energy` is at `EnergySystem.maxEnergy` so a long stretch at
    /// full never banks phantom ticks for later.
    var lastEnergyUpdateAt: Date
    /// Calendar day `energyRefillCount` is counting against — resets both
    /// once the stored day no longer matches today, same pattern as
    /// `rewardedAdWatchDay`.
    var energyRefillDay: Date
    var energyRefillCount: Int
    /// Arena Tower progress — the next floor (1...`ArenaSystem.maxFloor`) the
    /// player will fight; a value beyond `maxFloor` means the tower is fully
    /// cleared. Only ever advances on a win — see `GameState.applyArenaBattleResult`.
    var arenaFloor: Int
    /// Daily attempts left for the Arena Tower — deliberately its own ticket
    /// economy instead of spending shared `energy`, so climbing the tower
    /// never competes with Campaign stages for the same stamina bar.
    var arenaTickets: Int
    /// Calendar day `arenaTickets` was last refilled to `ArenaSystem.maxTicketsPerDay`
    /// — resets both once the stored day no longer matches today, same
    /// pattern as `energyRefillDay`.
    var arenaTicketDay: Date
    /// Non-resetting Arena ticket balance, spent only after the daily free
    /// `arenaTickets` run out — see `GameState.makeArenaBattleEngine`. Filled
    /// by real-money purchases (`ShopItemKind.arenaTicketPack` — tickets are
    /// never buyable with gold) and Battle Pass reward tiers. Deliberately
    /// separate from `arenaTickets` so a day rollover never silently wastes
    /// a purchase.
    var arenaBonusTickets: Int
    /// Prestige/Rebirth ("Wiedergeburt") currency — banked when the player
    /// resets the Arena Tower via `GameState.performRebirth()`, spent on
    /// permanent `SoulUpgrade` ranks. See `RebirthSystem`.
    var soulPoints: Int
    /// Rank (0...`RebirthSystem.maxRank(_:)`) bought so far per `SoulUpgrade`,
    /// keyed by `SoulUpgrade.rawValue`. A track absent from the dictionary is
    /// rank 0.
    var soulUpgradeRanks: [String: Int]
    /// Number of times the player has performed a Rebirth — display-only.
    var rebirthCount: Int
    /// Dungeon Keys left today — refilled to `DungeonSystem.maxKeysPerDay` at
    /// local midnight, same pattern as `arenaTickets`.
    var dungeonKeys: Int
    /// Calendar day `dungeonKeys` was last refilled — resets it once the
    /// stored day no longer matches today, same pattern as `arenaTicketDay`.
    var dungeonKeyDay: Date
    /// `DungeonID.storageKey`s the player has cleared at least once — gates
    /// the first-clear reward vs. the smaller repeat farm reward.
    var clearedDungeonIDs: Set<String>
    /// Free single-pull tickets for Dreamkeeper Summoning — spent instead of
    /// `dreamGems` by `GameState.performSummon()` whenever the balance is
    /// above 0, so an early or gem-poor player still gets the occasional
    /// summon. Earned from `LoginRewardSystem` days and select
    /// `DailyMissions`/`WeeklyMissions` (never purchasable — see
    /// `ShopItemKind`). Multi-pulls always spend gems; tickets only ever
    /// cover a single pull.
    var monsterSummonTickets: Int
    /// Same idea as `monsterSummonTickets`, but for Equipment Summoning
    /// (`GameState.performEquipmentSummon()`) — kept as its own counter
    /// rather than one shared pool so earning one never silently spends on
    /// the other kind of pull.
    var equipmentSummonTickets: Int

    init(playerLevel: Int, playerExp: Int, gold: Int, dreamGems: Int,
         roster: [DreamkeeperInstance], teams: [Team], activeTeamID: UUID, inventory: [EquipmentItem],
         currentStage: Int, lastGoldCollectedAt: Date, lastTrainingCollectedAt: Date,
         dailyMissionDay: Date, dailyMissionProgress: [String: Int], claimedMissionIDs: Set<String>,
         dailyMissionSelectedIDs: [String] = [],
         weeklyMissionWeek: Date = .distantPast, weeklyMissionProgress: [String: Int] = [:],
         claimedWeeklyMissionIDs: Set<String> = [],
         purchasedOneTimeOfferIDs: Set<String>, hapticsEnabled: Bool = true, soundEnabled: Bool = true,
         discoveredMonsters: Set<String> = [], battlePassXP: Int = 0, battlePassPremiumUnlocked: Bool = false,
         claimedBattlePassRewardIDs: Set<String> = [], preferredLanguage: String? = nil,
         notificationsEnabled: Bool = false, hasSeenOnboarding: Bool = true,
         hasChosenStarterElement: Bool = true,
         unlockedAchievementIDs: Set<String> = [], loginStreakDay: Int = 0,
         lastLoginRewardClaimDate: Date = .distantPast, isVIP: Bool = false,
         lastRewardedAdClaimedAt: Date = .distantPast, rewardedAdWatchDay: Date = .distantPast,
         rewardedAdWatchCount: Int = 0, stagesSinceLastInterstitial: Int = 0,
         lastInterstitialShownAt: Date = .distantPast, pullsSinceEpicSummon: Int = 0,
         pullsSinceLegendarySummon: Int = 0, hasUsedBeginnerMultiSummon: Bool = false,
         battleSpeedMultiplier: Double = 1.0, autoBattleEnabled: Bool = false,
         energy: Int = EnergySystem.maxEnergy, lastEnergyUpdateAt: Date = Date(),
         energyRefillDay: Date = .distantPast, energyRefillCount: Int = 0,
         arenaFloor: Int = 1, arenaTickets: Int = ArenaSystem.maxTicketsPerDay, arenaTicketDay: Date = .distantPast,
         arenaBonusTickets: Int = 0, soulPoints: Int = 0, soulUpgradeRanks: [String: Int] = [:],
         rebirthCount: Int = 0, dungeonKeys: Int = DungeonSystem.maxKeysPerDay, dungeonKeyDay: Date = .distantPast,
         clearedDungeonIDs: Set<String> = [], monsterSummonTickets: Int = 0, equipmentSummonTickets: Int = 0) {
        self.playerLevel = playerLevel
        self.playerExp = playerExp
        self.gold = gold
        self.dreamGems = dreamGems
        self.roster = roster
        self.teams = teams
        self.activeTeamID = activeTeamID
        self.inventory = inventory
        self.currentStage = currentStage
        self.lastGoldCollectedAt = lastGoldCollectedAt
        self.lastTrainingCollectedAt = lastTrainingCollectedAt
        self.dailyMissionDay = dailyMissionDay
        self.dailyMissionProgress = dailyMissionProgress
        self.claimedMissionIDs = claimedMissionIDs
        self.dailyMissionSelectedIDs = dailyMissionSelectedIDs
        self.weeklyMissionWeek = weeklyMissionWeek
        self.weeklyMissionProgress = weeklyMissionProgress
        self.claimedWeeklyMissionIDs = claimedWeeklyMissionIDs
        self.purchasedOneTimeOfferIDs = purchasedOneTimeOfferIDs
        self.hapticsEnabled = hapticsEnabled
        self.soundEnabled = soundEnabled
        self.discoveredMonsters = discoveredMonsters
        self.battlePassXP = battlePassXP
        self.battlePassPremiumUnlocked = battlePassPremiumUnlocked
        self.claimedBattlePassRewardIDs = claimedBattlePassRewardIDs
        self.preferredLanguage = preferredLanguage
        self.notificationsEnabled = notificationsEnabled
        self.hasSeenOnboarding = hasSeenOnboarding
        self.hasChosenStarterElement = hasChosenStarterElement
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.loginStreakDay = loginStreakDay
        self.lastLoginRewardClaimDate = lastLoginRewardClaimDate
        self.isVIP = isVIP
        self.lastRewardedAdClaimedAt = lastRewardedAdClaimedAt
        self.rewardedAdWatchDay = rewardedAdWatchDay
        self.rewardedAdWatchCount = rewardedAdWatchCount
        self.stagesSinceLastInterstitial = stagesSinceLastInterstitial
        self.lastInterstitialShownAt = lastInterstitialShownAt
        self.pullsSinceEpicSummon = pullsSinceEpicSummon
        self.pullsSinceLegendarySummon = pullsSinceLegendarySummon
        self.hasUsedBeginnerMultiSummon = hasUsedBeginnerMultiSummon
        self.battleSpeedMultiplier = battleSpeedMultiplier
        self.autoBattleEnabled = autoBattleEnabled
        self.energy = energy
        self.lastEnergyUpdateAt = lastEnergyUpdateAt
        self.energyRefillDay = energyRefillDay
        self.energyRefillCount = energyRefillCount
        self.arenaFloor = arenaFloor
        self.arenaTickets = arenaTickets
        self.arenaTicketDay = arenaTicketDay
        self.arenaBonusTickets = arenaBonusTickets
        self.soulPoints = soulPoints
        self.soulUpgradeRanks = soulUpgradeRanks
        self.rebirthCount = rebirthCount
        self.dungeonKeys = dungeonKeys
        self.dungeonKeyDay = dungeonKeyDay
        self.clearedDungeonIDs = clearedDungeonIDs
        self.monsterSummonTickets = monsterSummonTickets
        self.equipmentSummonTickets = equipmentSummonTickets
    }

    /// Custom decode so saves written before the offline-building timestamps
    /// existed (or before `lastOfflineTimestamp` was split into two) still
    /// load instead of crashing on missing keys.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerLevel = try container.decode(Int.self, forKey: .playerLevel)
        playerExp = try container.decode(Int.self, forKey: .playerExp)
        gold = try container.decode(Int.self, forKey: .gold)
        dreamGems = try container.decode(Int.self, forKey: .dreamGems)
        roster = try container.decode([DreamkeeperInstance].self, forKey: .roster)
        if let decodedTeams = try container.decodeIfPresent([Team].self, forKey: .teams), !decodedTeams.isEmpty {
            teams = decodedTeams
            activeTeamID = try container.decodeIfPresent(UUID.self, forKey: .activeTeamID) ?? decodedTeams[0].id
        } else if let legacyTeam = try container.decodeIfPresent(Team.self, forKey: .team) {
            teams = [legacyTeam]
            activeTeamID = legacyTeam.id
        } else {
            let fallback = Team()
            teams = [fallback]
            activeTeamID = fallback.id
        }
        inventory = try container.decode([EquipmentItem].self, forKey: .inventory)
        currentStage = try container.decode(Int.self, forKey: .currentStage)
        let legacyFallback = try container.decodeIfPresent(Date.self, forKey: .lastOfflineTimestamp) ?? Date()
        lastGoldCollectedAt = try container.decodeIfPresent(Date.self, forKey: .lastGoldCollectedAt) ?? legacyFallback
        lastTrainingCollectedAt = try container.decodeIfPresent(Date.self, forKey: .lastTrainingCollectedAt) ?? legacyFallback
        dailyMissionDay = try container.decodeIfPresent(Date.self, forKey: .dailyMissionDay) ?? .distantPast
        dailyMissionProgress = try container.decodeIfPresent([String: Int].self, forKey: .dailyMissionProgress) ?? [:]
        claimedMissionIDs = try container.decodeIfPresent(Set<String>.self, forKey: .claimedMissionIDs) ?? []
        // Missing/empty means this save predates mission rotation (or hasn't
        // drawn today's board yet) — `ensureMissionsCurrent` backfills it.
        dailyMissionSelectedIDs = try container.decodeIfPresent([String].self, forKey: .dailyMissionSelectedIDs) ?? []
        weeklyMissionWeek = try container.decodeIfPresent(Date.self, forKey: .weeklyMissionWeek) ?? .distantPast
        weeklyMissionProgress = try container.decodeIfPresent([String: Int].self, forKey: .weeklyMissionProgress) ?? [:]
        claimedWeeklyMissionIDs = try container.decodeIfPresent(Set<String>.self, forKey: .claimedWeeklyMissionIDs) ?? []
        purchasedOneTimeOfferIDs = try container.decodeIfPresent(Set<String>.self, forKey: .purchasedOneTimeOfferIDs) ?? []
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        discoveredMonsters = try container.decodeIfPresent(Set<String>.self, forKey: .discoveredMonsters) ?? []
        battlePassXP = try container.decodeIfPresent(Int.self, forKey: .battlePassXP) ?? 0
        battlePassPremiumUnlocked = try container.decodeIfPresent(Bool.self, forKey: .battlePassPremiumUnlocked) ?? false
        claimedBattlePassRewardIDs = try container.decodeIfPresent(Set<String>.self, forKey: .claimedBattlePassRewardIDs) ?? []
        preferredLanguage = try container.decodeIfPresent(String.self, forKey: .preferredLanguage)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        // Missing key means this save predates onboarding — treat as already
        // seen so an existing player is never dropped into it retroactively.
        hasSeenOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasSeenOnboarding) ?? true
        // Missing key means this save predates the starter-Olf-element choice
        // (or already carries a resolved non-placeholder starter from before
        // the feature existed) — treat as already chosen so it never
        // retroactively interrupts an existing player.
        hasChosenStarterElement = try container.decodeIfPresent(Bool.self, forKey: .hasChosenStarterElement) ?? true
        unlockedAchievementIDs = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedAchievementIDs) ?? []
        loginStreakDay = try container.decodeIfPresent(Int.self, forKey: .loginStreakDay) ?? 0
        lastLoginRewardClaimDate = try container.decodeIfPresent(Date.self, forKey: .lastLoginRewardClaimDate) ?? .distantPast
        isVIP = try container.decodeIfPresent(Bool.self, forKey: .isVIP) ?? false
        lastRewardedAdClaimedAt = try container.decodeIfPresent(Date.self, forKey: .lastRewardedAdClaimedAt) ?? .distantPast
        rewardedAdWatchDay = try container.decodeIfPresent(Date.self, forKey: .rewardedAdWatchDay) ?? .distantPast
        rewardedAdWatchCount = try container.decodeIfPresent(Int.self, forKey: .rewardedAdWatchCount) ?? 0
        stagesSinceLastInterstitial = try container.decodeIfPresent(Int.self, forKey: .stagesSinceLastInterstitial) ?? 0
        lastInterstitialShownAt = try container.decodeIfPresent(Date.self, forKey: .lastInterstitialShownAt) ?? .distantPast
        pullsSinceEpicSummon = try container.decodeIfPresent(Int.self, forKey: .pullsSinceEpicSummon) ?? 0
        pullsSinceLegendarySummon = try container.decodeIfPresent(Int.self, forKey: .pullsSinceLegendarySummon) ?? 0
        // Missing key means this save predates the Beginner's Banner guarantee —
        // treat as already used so an existing player's next 10x pull doesn't
        // suddenly get a floor they never opted into mid-progress.
        hasUsedBeginnerMultiSummon = try container.decodeIfPresent(Bool.self, forKey: .hasUsedBeginnerMultiSummon) ?? true
        battleSpeedMultiplier = try container.decodeIfPresent(Double.self, forKey: .battleSpeedMultiplier) ?? 1.0
        autoBattleEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoBattleEnabled) ?? false
        // Missing key means this save predates the Energy system — start
        // existing players full rather than at 0 so it never retroactively
        // locks them out on the update that introduced it.
        energy = try container.decodeIfPresent(Int.self, forKey: .energy) ?? EnergySystem.maxEnergy
        lastEnergyUpdateAt = try container.decodeIfPresent(Date.self, forKey: .lastEnergyUpdateAt) ?? Date()
        energyRefillDay = try container.decodeIfPresent(Date.self, forKey: .energyRefillDay) ?? .distantPast
        energyRefillCount = try container.decodeIfPresent(Int.self, forKey: .energyRefillCount) ?? 0
        // Missing key means this save predates the Arena Tower rework (or the
        // old rating-ladder Arena) — start existing players at floor 1, same
        // as a fresh save.
        arenaFloor = try container.decodeIfPresent(Int.self, forKey: .arenaFloor) ?? 1
        arenaTickets = try container.decodeIfPresent(Int.self, forKey: .arenaTickets) ?? ArenaSystem.maxTicketsPerDay
        arenaTicketDay = try container.decodeIfPresent(Date.self, forKey: .arenaTicketDay) ?? .distantPast
        arenaBonusTickets = try container.decodeIfPresent(Int.self, forKey: .arenaBonusTickets) ?? 0
        // Missing keys mean this save predates Rebirth/Dungeons — start
        // existing players with a clean slate, same as a fresh save.
        soulPoints = try container.decodeIfPresent(Int.self, forKey: .soulPoints) ?? 0
        soulUpgradeRanks = try container.decodeIfPresent([String: Int].self, forKey: .soulUpgradeRanks) ?? [:]
        rebirthCount = try container.decodeIfPresent(Int.self, forKey: .rebirthCount) ?? 0
        dungeonKeys = try container.decodeIfPresent(Int.self, forKey: .dungeonKeys) ?? DungeonSystem.maxKeysPerDay
        dungeonKeyDay = try container.decodeIfPresent(Date.self, forKey: .dungeonKeyDay) ?? .distantPast
        clearedDungeonIDs = try container.decodeIfPresent(Set<String>.self, forKey: .clearedDungeonIDs) ?? []
        // Missing keys mean this save predates summon tickets — start
        // existing players at 0, same as a fresh save that hasn't earned any
        // yet (never a paid currency, so there's nothing to backfill).
        monsterSummonTickets = try container.decodeIfPresent(Int.self, forKey: .monsterSummonTickets) ?? 0
        equipmentSummonTickets = try container.decodeIfPresent(Int.self, forKey: .equipmentSummonTickets) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerLevel, forKey: .playerLevel)
        try container.encode(playerExp, forKey: .playerExp)
        try container.encode(gold, forKey: .gold)
        try container.encode(dreamGems, forKey: .dreamGems)
        try container.encode(roster, forKey: .roster)
        try container.encode(teams, forKey: .teams)
        try container.encode(activeTeamID, forKey: .activeTeamID)
        try container.encode(inventory, forKey: .inventory)
        try container.encode(currentStage, forKey: .currentStage)
        try container.encode(lastGoldCollectedAt, forKey: .lastGoldCollectedAt)
        try container.encode(lastTrainingCollectedAt, forKey: .lastTrainingCollectedAt)
        try container.encode(dailyMissionDay, forKey: .dailyMissionDay)
        try container.encode(dailyMissionProgress, forKey: .dailyMissionProgress)
        try container.encode(claimedMissionIDs, forKey: .claimedMissionIDs)
        try container.encode(dailyMissionSelectedIDs, forKey: .dailyMissionSelectedIDs)
        try container.encode(weeklyMissionWeek, forKey: .weeklyMissionWeek)
        try container.encode(weeklyMissionProgress, forKey: .weeklyMissionProgress)
        try container.encode(claimedWeeklyMissionIDs, forKey: .claimedWeeklyMissionIDs)
        try container.encode(purchasedOneTimeOfferIDs, forKey: .purchasedOneTimeOfferIDs)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(soundEnabled, forKey: .soundEnabled)
        try container.encode(discoveredMonsters, forKey: .discoveredMonsters)
        try container.encode(battlePassXP, forKey: .battlePassXP)
        try container.encode(battlePassPremiumUnlocked, forKey: .battlePassPremiumUnlocked)
        try container.encode(claimedBattlePassRewardIDs, forKey: .claimedBattlePassRewardIDs)
        try container.encodeIfPresent(preferredLanguage, forKey: .preferredLanguage)
        try container.encode(notificationsEnabled, forKey: .notificationsEnabled)
        try container.encode(hasSeenOnboarding, forKey: .hasSeenOnboarding)
        try container.encode(hasChosenStarterElement, forKey: .hasChosenStarterElement)
        try container.encode(unlockedAchievementIDs, forKey: .unlockedAchievementIDs)
        try container.encode(loginStreakDay, forKey: .loginStreakDay)
        try container.encode(lastLoginRewardClaimDate, forKey: .lastLoginRewardClaimDate)
        try container.encode(isVIP, forKey: .isVIP)
        try container.encode(lastRewardedAdClaimedAt, forKey: .lastRewardedAdClaimedAt)
        try container.encode(rewardedAdWatchDay, forKey: .rewardedAdWatchDay)
        try container.encode(rewardedAdWatchCount, forKey: .rewardedAdWatchCount)
        try container.encode(stagesSinceLastInterstitial, forKey: .stagesSinceLastInterstitial)
        try container.encode(lastInterstitialShownAt, forKey: .lastInterstitialShownAt)
        try container.encode(pullsSinceEpicSummon, forKey: .pullsSinceEpicSummon)
        try container.encode(pullsSinceLegendarySummon, forKey: .pullsSinceLegendarySummon)
        try container.encode(hasUsedBeginnerMultiSummon, forKey: .hasUsedBeginnerMultiSummon)
        try container.encode(battleSpeedMultiplier, forKey: .battleSpeedMultiplier)
        try container.encode(autoBattleEnabled, forKey: .autoBattleEnabled)
        try container.encode(energy, forKey: .energy)
        try container.encode(lastEnergyUpdateAt, forKey: .lastEnergyUpdateAt)
        try container.encode(energyRefillDay, forKey: .energyRefillDay)
        try container.encode(energyRefillCount, forKey: .energyRefillCount)
        try container.encode(arenaFloor, forKey: .arenaFloor)
        try container.encode(arenaTickets, forKey: .arenaTickets)
        try container.encode(arenaTicketDay, forKey: .arenaTicketDay)
        try container.encode(arenaBonusTickets, forKey: .arenaBonusTickets)
        try container.encode(soulPoints, forKey: .soulPoints)
        try container.encode(soulUpgradeRanks, forKey: .soulUpgradeRanks)
        try container.encode(rebirthCount, forKey: .rebirthCount)
        try container.encode(dungeonKeys, forKey: .dungeonKeys)
        try container.encode(dungeonKeyDay, forKey: .dungeonKeyDay)
        try container.encode(clearedDungeonIDs, forKey: .clearedDungeonIDs)
        try container.encode(monsterSummonTickets, forKey: .monsterSummonTickets)
        try container.encode(equipmentSummonTickets, forKey: .equipmentSummonTickets)
    }

    private enum CodingKeys: String, CodingKey {
        case playerLevel, playerExp, gold, dreamGems, roster, teams, activeTeamID, inventory, currentStage
        case lastGoldCollectedAt, lastTrainingCollectedAt
        case dailyMissionDay, dailyMissionProgress, claimedMissionIDs, dailyMissionSelectedIDs
        case weeklyMissionWeek, weeklyMissionProgress, claimedWeeklyMissionIDs
        case purchasedOneTimeOfferIDs, hapticsEnabled, soundEnabled, discoveredMonsters
        case battlePassXP, battlePassPremiumUnlocked, claimedBattlePassRewardIDs, preferredLanguage
        case notificationsEnabled, hasSeenOnboarding, hasChosenStarterElement, unlockedAchievementIDs
        case loginStreakDay, lastLoginRewardClaimDate
        case isVIP, lastRewardedAdClaimedAt
        case rewardedAdWatchDay, rewardedAdWatchCount
        case stagesSinceLastInterstitial, lastInterstitialShownAt
        case pullsSinceEpicSummon, pullsSinceLegendarySummon, hasUsedBeginnerMultiSummon
        case battleSpeedMultiplier, autoBattleEnabled
        case energy, lastEnergyUpdateAt, energyRefillDay, energyRefillCount
        case arenaFloor, arenaTickets, arenaTicketDay, arenaBonusTickets
        case soulPoints, soulUpgradeRanks, rebirthCount, dungeonKeys, dungeonKeyDay, clearedDungeonIDs
        case monsterSummonTickets, equipmentSummonTickets
        case team // legacy key, migration-only
        case lastOfflineTimestamp // legacy key, migration-only
    }

    static func newGame(starterDefinitionID: String) -> GameSave {
        let starter = DreamkeeperInstance(definitionID: starterDefinitionID)
        let mainTeam = Team(memberIDs: [starter.id])
        let now = Date()
        return GameSave(
            playerLevel: 1,
            playerExp: 0,
            gold: 100,
            dreamGems: 50,
            roster: [starter],
            teams: [mainTeam],
            activeTeamID: mainTeam.id,
            inventory: [],
            currentStage: 1,
            lastGoldCollectedAt: now,
            lastTrainingCollectedAt: now,
            dailyMissionDay: .distantPast,
            dailyMissionProgress: [:],
            claimedMissionIDs: [],
            purchasedOneTimeOfferIDs: [],
            hasSeenOnboarding: false,
            hasChosenStarterElement: false,
            // A free ticket of each kind from the very first launch — a
            // brand new player can summon once before ever earning or
            // spending a single extra Dream Gem.
            monsterSummonTickets: 1,
            equipmentSummonTickets: 1
        )
    }
}
