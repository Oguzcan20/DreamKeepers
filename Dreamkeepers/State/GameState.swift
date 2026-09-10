import Foundation
import Observation

struct LevelUpSummary: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var oldLevel: Int
    var newLevel: Int
    var statsBefore: Stats
    var statsAfter: Stats
}

struct AccountLevelUp: Equatable {
    var oldLevel: Int
    var newLevel: Int
}

/// Result of one Arena Tower floor fight — deliberately its own type rather
/// than reusing `BattleResultSummary`: this never touches roster EXP/levels
/// or campaign progress, and adds tower-specific concepts (`isMilestoneFloor`,
/// `towerCleared`) that don't apply to a campaign stage.
struct ArenaBattleResultSummary: Equatable {
    var outcome: BattleOutcome
    var floor: Int
    var goldGained: Int
    var newTier: ArenaTier
    var tierChanged: Bool
    var droppedEquipment: EquipmentItem?
    /// True when this win was `floor`'s very first clear (bigger, fixed
    /// reward, and the one that advances `GameState.arenaFloor`) rather than
    /// a replay of an already-cleared floor (smaller, RNG farm reward).
    var isFirstClear: Bool
    /// True when `floor` was a multiple of `ArenaSystem.milestoneInterval`
    /// AND this was its first clear — the result screen calls this out as a
    /// guaranteed legendary reward, not just another floor clear. Replaying
    /// a milestone floor later only ever pays the standard reward.
    var isMilestoneFloor: Bool
    /// True the instant `floor` was `ArenaSystem.maxFloor` and its first
    /// clear was won — the tower has no floor 101, so this is a distinct,
    /// one-time "you've beaten the whole thing" moment rather than an
    /// ordinary climb.
    var towerCleared: Bool
}

struct BattleResultSummary: Equatable {
    var outcome: BattleOutcome
    var stage: Int
    var wasBoss: Bool
    var goldGained: Int
    var expGained: Int
    /// Dream Gems from `WorldClearRewardSystem` — non-zero only the instant
    /// a World's boss is cleared for the first time (see
    /// `completedWorldNumber`); 0 on every other stage clear, boss or not.
    var gemsGained: Int = 0
    var levelUps: [LevelUpSummary]
    var newRecruit: DreamkeeperDefinition?
    var droppedEquipment: EquipmentItem?
    var accountLevelUp: AccountLevelUp?
    /// True when the whole party ended the fight at full HP — a bonus-
    /// worthy feat worth calling out on the result screen, not just another
    /// win indistinguishable from a scraped-through one.
    var isPerfectClear: Bool = false
    var perfectClearBonusGold: Int = 0
    /// Non-nil exactly when `gemsGained` was just paid out — the World
    /// number that was completed, so the result screen can call it out by
    /// name ("World 5 completed!") rather than just showing a gem count.
    var completedWorldNumber: Int?
}

/// App-wide root state: the single source of truth the UI reads and mutates.
/// Owns persistence (via SaveSystem) and content (via DreamkeeperCatalog) but
/// stays free of SwiftUI imports so it could back a different UI layer later.
@Observable
final class GameState {
    let catalog: DreamkeeperCatalog
    private let platform: PlatformService
    private let saveSystem: SaveSystem
    private let adService: AdRewardService
    private let interstitialAdService: InterstitialAdService
    private let purchaseService: PurchaseService

    private(set) var save: GameSave

    /// Which stage a battle will be fought at — distinct from `save.currentStage`
    /// (the progression frontier) so cleared stages can be replayed without
    /// re-advancing the campaign or re-granting boss rewards.
    private(set) var selectedStage: Int

    /// Newly-unlocked achievements waiting for their celebration popup —
    /// transient (not persisted; `save.unlockedAchievementIDs` is the
    /// durable record). `RootView` drains this one at a time regardless of
    /// which screen is currently showing.
    private(set) var pendingAchievements: [Achievement] = []

    func consumeNextPendingAchievement() -> Achievement? {
        pendingAchievements.isEmpty ? nil : pendingAchievements.removeFirst()
    }

    init(platform: PlatformService = iOSPlatformService(),
         saveSystem: SaveSystem? = nil,
         catalog: DreamkeeperCatalog = .starter,
         adService: AdRewardService = AdMobRewardService(),
         interstitialAdService: InterstitialAdService = AdMobInterstitialAdService(),
         purchaseService: PurchaseService = StoreKitPurchaseService()) {
        self.platform = platform
        self.saveSystem = saveSystem ?? CloudSaveStore(platform: platform)
        self.catalog = catalog
        self.interstitialAdService = interstitialAdService
        self.adService = adService
        self.purchaseService = purchaseService
        let loaded = self.saveSystem.load() ?? .newGame(starterDefinitionID: DreamkeeperCatalog.starterOlfDefaultID)
        self.save = loaded
        self.selectedStage = min(loaded.currentStage, WorldCatalog.totalStages)
        persist()
        if loaded.notificationsEnabled {
            // Re-arm both building timers on every cold launch (cheap and
            // idempotent — same identifiers just get replaced) so a pending
            // reminder that already fired, or never got scheduled before a
            // force-quit, is always caught up rather than silently missing.
            scheduleBuildingNotifications()
        }
        if let storeKitService = purchaseService as? StoreKitPurchaseService {
            // Synchronous, direct assignment — `onExternalPurchase` is
            // `nonisolated(unsafe)` specifically so this doesn't need a
            // `@MainActor` hop (and the data-race risk that comes with
            // "sending" a non-`Sendable`, non-isolated `self` across actors
            // from within `init`). See that property's doc comment.
            storeKitService.onExternalPurchase = { [weak self] productID in
                self?.grantPurchase(forProductID: productID)
            }
        }
    }

    /// Grants the `ShopItem` matching `productID` — called for a verified
    /// transaction StoreKit reports outside the interactive purchase flow (a
    /// restore, or an Ask-to-Buy approval that completes after the original
    /// `purchaseWithRealMoney` call already returned).
    private func grantPurchase(forProductID productID: String) {
        guard let item = ShopCatalog.allRealMoneyItems.first(where: { $0.productID == productID }) else { return }
        purchase(item)
    }

    // MARK: - Persistence

    func persist() {
        try? saveSystem.save(save)
    }

    // MARK: - Achievements

    /// Re-evaluates every not-yet-unlocked `AchievementSystem` milestone
    /// against current state and queues any that just became true. Cheap
    /// enough (a dozen simple predicates) to call after any mutation that
    /// could plausibly complete one, rather than threading a specific
    /// "check this one achievement" call through every call site.
    @discardableResult
    func checkAchievements(context: AchievementContext = AchievementContext()) -> [Achievement] {
        var unlocked: [Achievement] = []
        for achievement in AchievementSystem.all where !save.unlockedAchievementIDs.contains(achievement.id) {
            if achievement.predicate(self, context) {
                save.unlockedAchievementIDs.insert(achievement.id)
                unlocked.append(achievement)
            }
        }
        if !unlocked.isEmpty {
            pendingAchievements.append(contentsOf: unlocked)
            persist()
        }
        return unlocked
    }

    // MARK: - Energy

    var maxEnergy: Int { EnergySystem.maxEnergy }

    /// Applies any regen owed since `lastEnergyUpdateAt` before returning
    /// the current total — called on every read so the displayed number is
    /// always live without needing a running timer.
    var energy: Int {
        refreshEnergy()
        return save.energy
    }

    /// Seconds until the next point regenerates, or nil once the bar is
    /// already full. Drives the small countdown next to the Energy pill.
    var secondsUntilNextEnergy: Int? {
        refreshEnergy()
        guard save.energy < EnergySystem.maxEnergy else { return nil }
        let elapsed = Date().timeIntervalSince(save.lastEnergyUpdateAt)
        return max(0, Int(EnergySystem.regenIntervalSeconds - elapsed))
    }

    func canAffordEnergy(_ amount: Int) -> Bool { energy >= amount }

    /// Advances `save.energy` by however many `regenIntervalSeconds` ticks
    /// have elapsed since the stored baseline, preserving any leftover
    /// partial progress toward the next tick.
    ///
    /// Deliberately a no-op (touches nothing on `save`) whenever there's
    /// nothing to apply. `energy`/`secondsUntilNextEnergy` call this on
    /// every read, including from view bodies (the Energy pill) — `save` is
    /// an `@Observable`-tracked property, so writing to it unconditionally
    /// here would invalidate the very view that just read it and re-trigger
    /// this same read-then-write on the next body evaluation, hanging the
    /// app in a render loop the instant a full-energy save opened Dream
    /// Haven. Only a *real* state change (an elapsed tick) may write.
    private func refreshEnergy() {
        guard save.energy < EnergySystem.maxEnergy else { return }
        let elapsed = Date().timeIntervalSince(save.lastEnergyUpdateAt)
        let ticks = Int(elapsed / EnergySystem.regenIntervalSeconds)
        guard ticks > 0 else { return }
        save.energy = min(EnergySystem.maxEnergy, save.energy + ticks)
        save.lastEnergyUpdateAt = save.lastEnergyUpdateAt.addingTimeInterval(Double(ticks) * EnergySystem.regenIntervalSeconds)
        persist()
    }

    /// Tops energy up without exceeding the cap — used by mission/login
    /// rewards, which would otherwise waste the overflow on a full bar.
    /// Called only from explicit reward-claim actions (never from a passive
    /// read), so pinning the regen baseline to "now" here is safe.
    private func grantEnergy(_ amount: Int) {
        guard amount > 0 else { return }
        refreshEnergy()
        save.energy = min(EnergySystem.maxEnergy, save.energy + amount)
        if save.energy >= EnergySystem.maxEnergy {
            save.lastEnergyUpdateAt = Date()
        }
    }

    @discardableResult
    func spendEnergy(_ amount: Int) -> Bool {
        guard canAffordEnergy(amount) else { return false }
        // The regen clock doesn't run while the bar is full (see
        // `refreshEnergy`), so a bar that's been sitting at max for days
        // still has a stale baseline. Reset it here, at the moment we spend
        // down from full, instead of letting the next read compute a huge
        // elapsed-time tick count and refill the bar right back to max.
        let wasFull = save.energy >= EnergySystem.maxEnergy
        save.energy -= amount
        if wasFull {
            save.lastEnergyUpdateAt = Date()
        }
        persist()
        return true
    }

    /// Calendar-day-scoped counter, same reset pattern as `rewardedAdWatchDay`.
    private func ensureEnergyRefillDayCurrent() {
        let today = Calendar.current.startOfDay(for: Date())
        guard !Calendar.current.isDate(save.energyRefillDay, inSameDayAs: today) else { return }
        save.energyRefillDay = today
        save.energyRefillCount = 0
    }

    var energyRefillsRemainingToday: Int {
        ensureEnergyRefillDayCurrent()
        return max(0, EnergySystem.maxRefillsPerDay - save.energyRefillCount)
    }

    var nextEnergyRefillGemCost: Int {
        ensureEnergyRefillDayCurrent()
        return EnergySystem.refillGemCost(refillsUsedToday: save.energyRefillCount)
    }

    var canRefillEnergyWithGems: Bool {
        energyRefillsRemainingToday > 0 && save.dreamGems >= nextEnergyRefillGemCost
    }

    /// Spends Dream Gems for an immediate `EnergySystem.energyPerRefill`
    /// top-up — the pay-to-skip-the-wait alternative to passive regen,
    /// capped per day so it can't fully replace pacing.
    @discardableResult
    func refillEnergyWithGems() -> Bool {
        ensureEnergyRefillDayCurrent()
        guard canRefillEnergyWithGems else { return false }
        save.dreamGems -= nextEnergyRefillGemCost
        save.energyRefillCount += 1
        grantEnergy(EnergySystem.energyPerRefill)
        persist()
        return true
    }

    // MARK: - Login streak

    /// True whenever today's login reward hasn't been claimed yet — true on
    /// a brand new save (`lastLoginRewardClaimDate` is `.distantPast`) and
    /// flips back to true every new calendar day.
    var isLoginRewardAvailable: Bool {
        !Calendar.current.isDateInToday(save.lastLoginRewardClaimDate)
    }

    /// The day (1...`LoginRewardSystem.cycleLength`) that `claimLoginReward()`
    /// would grant right now. Continues the streak if the last claim was
    /// yesterday, wrapping back to Day 1 after Day 7; otherwise (a lapsed
    /// streak, or the very first claim) restarts at Day 1.
    var nextLoginRewardDay: Int {
        if Calendar.current.isDateInYesterday(save.lastLoginRewardClaimDate) {
            return save.loginStreakDay % LoginRewardSystem.cycleLength + 1
        }
        return 1
    }

    /// Grants today's login-streak reward and advances the streak. No-op
    /// (returns nil) if already claimed today.
    @discardableResult
    func claimLoginReward() -> LoginRewardDay? {
        guard isLoginRewardAvailable, let reward = LoginRewardSystem.reward(forDay: nextLoginRewardDay) else { return nil }
        save.gold += reward.gold
        save.dreamGems += reward.gems
        grantEnergy(reward.energy)
        save.loginStreakDay = reward.day
        save.lastLoginRewardClaimDate = Date()
        persist()
        checkAchievements()
        return reward
    }

    // MARK: - Roster / team

    var roster: [DreamkeeperInstance] { save.roster }

    /// Distinct species owned — unlike `roster.count`, doesn't inflate with
    /// duplicate copies kept around as fusion fodder.
    var ownedSpeciesCount: Int { Set(save.roster.map(\.definitionID)).count }

    static let maxTeams = 5

    var teams: [Team] { save.teams }
    var activeTeamID: UUID { save.activeTeamID }

    private var activeTeamIndex: Int {
        save.teams.firstIndex { $0.id == save.activeTeamID } ?? 0
    }

    var activeTeam: Team { save.teams[activeTeamIndex] }

    func setActiveTeam(_ id: UUID) {
        guard save.teams.contains(where: { $0.id == id }) else { return }
        save.activeTeamID = id
        persist()
    }

    @discardableResult
    func createTeam() -> Team? {
        guard save.teams.count < Self.maxTeams else { return nil }
        let newTeam = Team(name: "Team \(save.teams.count + 1)")
        save.teams.append(newTeam)
        persist()
        return newTeam
    }

    var deployedTeam: [DreamkeeperInstance] {
        save.teams[activeTeamIndex].memberIDs.compactMap { id in save.roster.first { $0.id == id } }
    }

    func isDeployed(_ instance: DreamkeeperInstance) -> Bool {
        save.teams[activeTeamIndex].memberIDs.contains(instance.id)
    }

    func toggleDeployed(_ instance: DreamkeeperInstance) {
        if let idx = save.teams[activeTeamIndex].memberIDs.firstIndex(of: instance.id) {
            save.teams[activeTeamIndex].memberIDs.remove(at: idx)
        } else if save.teams[activeTeamIndex].memberIDs.count < Team.maxSize {
            save.teams[activeTeamIndex].memberIDs.append(instance.id)
        }
        if save.teams[activeTeamIndex].memberIDs.count == Team.maxSize {
            incrementMission(.deployFullTeam)
        }
        persist()
        checkAchievements()
    }

    func definition(for instance: DreamkeeperInstance) -> DreamkeeperDefinition? {
        catalog.definition(for: instance.definitionID)
    }

    // MARK: - Selling Dreamkeepers

    /// A Dreamkeeper can always be sold except the very last one in the
    /// roster — there always has to be at least one left to field. Igo and
    /// Ames are never sellable: they're permanent, one-of-a-kind Dreamwalkers,
    /// not fusion fodder — see `TwinBond`.
    func canSellDreamkeeper(_ instance: DreamkeeperInstance) -> Bool {
        guard save.roster.count > 1, save.roster.contains(where: { $0.id == instance.id }) else { return false }
        return definition(for: instance)?.rarity != .exclusive
    }

    /// Gold (always) and Dream Gems (Legendary/Mythic only) a sale would pay
    /// out right now, for the confirmation UI. See `DreamkeeperSaleSystem`.
    func sellValue(for instance: DreamkeeperInstance) -> (gold: Int, gems: Int) {
        let rarity = definition(for: instance)?.rarity ?? .common
        return (
            DreamkeeperSaleSystem.goldValue(for: rarity, level: instance.level, stars: instance.stars),
            DreamkeeperSaleSystem.gemValue(for: rarity)
        )
    }

    /// Sells any number of roster Dreamkeepers at once — benching and
    /// unequipping each first so nothing is left pointing at a deleted
    /// instance. Ids that can't be sold (unknown, or would empty the whole
    /// roster) are skipped rather than failing the entire batch.
    @discardableResult
    func sellDreamkeepers(_ ids: Set<UUID>) -> (gold: Int, gems: Int, count: Int) {
        var totalGold = 0
        var totalGems = 0
        var sold = 0
        for id in ids {
            guard save.roster.count > 1,
                  let instance = save.roster.first(where: { $0.id == id }),
                  canSellDreamkeeper(instance) else { continue }
            let value = sellValue(for: instance)
            totalGold += value.gold
            totalGems += value.gems
            sold += 1
            for i in save.teams.indices {
                save.teams[i].memberIDs.removeAll { $0 == id }
            }
            save.roster.removeAll { $0.id == id }
        }
        guard sold > 0 else { return (0, 0, 0) }
        save.gold += totalGold
        save.dreamGems += totalGems
        persist()
        checkAchievements()
        return (totalGold, totalGems, sold)
    }

    // MARK: - Star fusion

    /// Other owned copies of the same species as `target` — fusion fodder,
    /// picked manually by the player rather than auto-consumed on summon.
    /// When `target`'s definition has a non-nil `family` (currently only
    /// Olf's six entries), any roster member sharing that family counts as
    /// a duplicate too, not just an exact `definitionID` match — so any Olf
    /// variant pulled later from Summoning can be fused straight into
    /// whichever one the player is actually raising. Every other
    /// Dreamkeeper (`family == nil`) keeps the original strict-`id` match.
    func duplicates(of target: DreamkeeperInstance) -> [DreamkeeperInstance] {
        guard let targetFamily = catalog.definition(for: target.definitionID)?.family else {
            return save.roster.filter { $0.definitionID == target.definitionID && $0.id != target.id }
        }
        return save.roster.filter { other in
            other.id != target.id &&
                (other.definitionID == target.definitionID || catalog.definition(for: other.definitionID)?.family == targetFamily)
        }
    }

    /// Duplicates required for `target`'s next star tier, or nil if already maxed.
    func nextFusionCost(for target: DreamkeeperInstance) -> Int? {
        guard target.stars < StarFusionSystem.maxStars else { return nil }
        return StarFusionSystem.duplicatesRequired(forTier: target.stars + 1)
    }

    /// `selected` just needs to be one or more real duplicates of `target`
    /// currently in the roster, with no repeats — a fuse no longer has to
    /// hand over an exact tier's cost in one go (see `fuseDreamkeeper`).
    func canFuseDreamkeeper(_ target: DreamkeeperInstance, consuming selected: [DreamkeeperInstance]) -> Bool {
        guard target.stars < StarFusionSystem.maxStars, !selected.isEmpty else { return false }
        let selectedIDs = Set(selected.map(\.id))
        guard selectedIDs.count == selected.count, !selectedIDs.contains(target.id) else { return false }
        let validDuplicateIDs = Set(duplicates(of: target).map(\.id))
        return selectedIDs.isSubset(of: validDuplicateIDs)
    }

    /// Deletes `selected` from the roster (and benches them if deployed),
    /// then banks their count onto `target.fusionProgress`, resolving as
    /// many star tier-ups as the combined total supports. Any duplicates
    /// short of the next tier's cost just sit banked for next time — the
    /// player can always fuse whatever they currently have instead of
    /// having to gather an exact amount before the button does anything.
    /// Returns false (no change) if `selected` isn't a valid, non-empty set
    /// of `target`'s duplicates — the UI should gate the fuse button on
    /// `canFuseDreamkeeper` so this is a safety net.
    @discardableResult
    func fuseDreamkeeper(_ target: DreamkeeperInstance, consuming selected: [DreamkeeperInstance]) -> Bool {
        guard canFuseDreamkeeper(target, consuming: selected) else { return false }
        let selectedIDs = Set(selected.map(\.id))
        save.roster.removeAll { selectedIDs.contains($0.id) }
        for i in save.teams.indices {
            save.teams[i].memberIDs.removeAll { selectedIDs.contains($0) }
        }
        guard let idx = save.roster.firstIndex(where: { $0.id == target.id }) else { return false }
        let result = StarFusionSystem.applyFusion(
            newDuplicates: selected.count, stars: save.roster[idx].stars, progress: save.roster[idx].fusionProgress
        )
        save.roster[idx].stars = result.stars
        save.roster[idx].fusionProgress = result.progress
        persist()
        checkAchievements()
        return true
    }

    // MARK: - Campaign / battle setup

    var currentStage: Int { save.currentStage }
    var isCampaignComplete: Bool { save.currentStage > WorldCatalog.totalStages }

    /// A stage is selectable once it's been unlocked by reaching it (replaying
    /// earlier stages is allowed; stages beyond the frontier are not).
    func isStageUnlocked(_ stage: Int) -> Bool {
        stage <= save.currentStage
    }

    func selectStage(_ stage: Int) {
        guard isStageUnlocked(stage), stage >= 1, stage <= WorldCatalog.totalStages else { return }
        selectedStage = stage
    }

    /// Selects `stage` and spends its Energy cost up front (boss stages
    /// cost more, see `EnergySystem.stageCost(isBoss:)`) — the gate every
    /// real fight goes through before the Battle screen ever opens, so a
    /// lost fight still costs the same as a won one. Returns false (no
    /// state change) when the stage can't be selected or Energy is short;
    /// callers should surface an insufficient-Energy prompt.
    @discardableResult
    func attemptStage(_ stage: Int) -> Bool {
        guard isStageUnlocked(stage), stage >= 1, stage <= WorldCatalog.totalStages else { return false }
        let isBoss = stage % World.stagesPerWorld == 0
        guard spendEnergy(EnergySystem.stageCost(isBoss: isBoss)) else { return false }
        selectedStage = stage
        persist()
        return true
    }

    /// Shared by `makeBattleEngine()` and `makeArenaBattleEngine(floor:)` so
    /// Campaign and Arena battles apply Zwillingsbund identically — the two
    /// used to build this list with separately-duplicated closures.
    private func makePlayerCombatants(from team: [DreamkeeperInstance]) -> [Combatant] {
        let twinBondActive = TwinBond.isActive(memberDefinitionIDs: team.map(\.definitionID))
        return team.compactMap { instance -> Combatant? in
            guard let def = definition(for: instance) else { return nil }
            var stats = instance.currentStats(in: catalog, inventory: save.inventory)
            if twinBondActive, TwinBond.isBondCharacter(instance.definitionID) {
                stats = Stats(
                    hp: stats.hp,
                    attack: stats.attack * (1 + TwinBond.statBonusMultiplier),
                    defense: stats.defense * (1 + TwinBond.statBonusMultiplier),
                    speed: stats.speed
                )
            }
            return Combatant(
                id: instance.id, name: def.name, element: def.element, role: def.role,
                isPlayer: true, isBoss: false, definitionID: instance.definitionID,
                maxHP: stats.hp, currentHP: stats.hp,
                attack: stats.attack, defense: stats.defense, speed: stats.speed,
                ultimate: def.ultimate, activeSkill: def.activeSkill,
                reviveHPFraction: def.passive.reviveHPFraction,
                lowHPAttackBonus: def.passive.lowHPAttackBonus
            )
        }
    }

    func makeBattleEngine() -> BattleEngine? {
        guard !deployedTeam.isEmpty else { return nil }
        let playerCombatants = makePlayerCombatants(from: deployedTeam)
        guard !playerCombatants.isEmpty else { return nil }
        let isBoss = selectedStage % World.stagesPerWorld == 0
        let enemy = EnemyFactory.enemy(forStage: selectedStage)
        return BattleEngine(playerUnits: playerCombatants, enemy: enemy, stage: selectedStage, isBossStage: isBoss)
    }

    // MARK: - Resolving a finished battle

    func applyBattleResult(from engine: BattleEngine) -> BattleResultSummary {
        let outcome = engine.outcome ?? .defeat
        let stage = engine.stage
        let isBoss = engine.isBossStage
        var levelUps: [LevelUpSummary] = []
        var goldGained = 0
        var expGained = 0
        var gemsGained = 0
        var completedWorldNumber: Int?
        var newRecruit: DreamkeeperDefinition?
        var droppedEquipment: EquipmentItem?
        var accountLevelUp: AccountLevelUp?
        var perfectClearBonusGold = 0
        let isPerfectClear = outcome == .victory && !engine.playerUnits.isEmpty
            && engine.playerUnits.allSatisfy { $0.currentHP >= $0.maxHP }

        for foe in engine.enemyUnits {
            save.discoveredMonsters.insert(foe.name)
        }

        if outcome == .victory {
            recordStageForInterstitialPacing()
            incrementMission(.winBattle)
            incrementMission(.premiumBonusStages)
            incrementWeeklyMission(.clearStages)
            if isBoss {
                incrementMission(.defeatBoss)
                incrementWeeklyMission(.defeatBosses)
            }
            let rewards = RewardTable.rewards(forStage: stage, isBoss: isBoss)
            goldGained = rewards.gold
            expGained = rewards.expPerSurvivor
            save.gold += rewards.gold
            save.battlePassXP += BattlePassSystem.xpGained(isBoss: isBoss)

            // A flat-out reward for not taking a single hit — worth more
            // than a quieter "you won" on the result screen.
            if isPerfectClear {
                perfectClearBonusGold = max(1, Int(Double(rewards.gold) * 0.25))
                goldGained += perfectClearBonusGold
                save.gold += perfectClearBonusGold
            }

            let accountBefore = save.playerLevel
            let accountResult = LevelSystem.applyExp(rewards.accountExp, level: save.playerLevel, exp: save.playerExp)
            save.playerLevel = accountResult.finalLevel
            save.playerExp = accountResult.finalExp
            if accountResult.levelsGained > 0 {
                accountLevelUp = AccountLevelUp(oldLevel: accountBefore, newLevel: accountResult.finalLevel)
            }

            let survivorIDs = Set(engine.playerUnits.filter(\.isAlive).map(\.id))
            for i in save.roster.indices where survivorIDs.contains(save.roster[i].id) {
                guard let def = definition(for: save.roster[i]) else { continue }
                let before = save.roster[i]
                let statsBefore = before.currentStats(in: catalog, inventory: save.inventory)

                let result = LevelSystem.applyExp(rewards.expPerSurvivor, level: before.level, exp: before.exp)
                save.roster[i].level = result.finalLevel
                save.roster[i].exp = result.finalExp

                if result.levelsGained > 0 {
                    let statsAfter = save.roster[i].currentStats(in: catalog, inventory: save.inventory)
                    levelUps.append(LevelUpSummary(
                        name: def.name, oldLevel: before.level, newLevel: result.finalLevel,
                        statsBefore: statsBefore, statsAfter: statsAfter
                    ))
                }
            }

            if EquipmentFactory.shouldDrop(isBoss: isBoss) {
                let item = EquipmentFactory.randomItem(forStage: stage, isBoss: isBoss)
                save.inventory.append(item)
                droppedEquipment = item
            }

            // Only the frontier stage advances the campaign — replaying an
            // earlier cleared stage still pays out but doesn't push progress
            // or re-grant a boss recruit.
            let wasFrontierClear = stage == save.currentStage
            if wasFrontierClear {
                save.currentStage += 1
                selectedStage = min(save.currentStage, WorldCatalog.totalStages)

                if isBoss {
                    newRecruit = grantNextRecruitIfAvailable()

                    // A whole World's worth of stages just got cleared for
                    // the first time — pay out the Dream Gems bonus on top
                    // of the recruit. Every 5th completed World pays the
                    // bigger milestone amount instead of the standard one.
                    let worldNumber = WorldCatalog.world(forStage: stage).id
                    gemsGained = WorldClearRewardSystem.gems(forCompletedWorld: worldNumber)
                    save.dreamGems += gemsGained
                    completedWorldNumber = worldNumber
                }
            }
        }

        persist()
        checkAchievements(context: AchievementContext(isPerfectClear: isPerfectClear))
        return BattleResultSummary(
            outcome: outcome, stage: stage, wasBoss: isBoss,
            goldGained: goldGained, expGained: expGained, gemsGained: gemsGained,
            levelUps: levelUps, newRecruit: newRecruit, droppedEquipment: droppedEquipment,
            accountLevelUp: accountLevelUp,
            isPerfectClear: isPerfectClear, perfectClearBonusGold: perfectClearBonusGold,
            completedWorldNumber: completedWorldNumber
        )
    }

    // MARK: - Arena Tower

    var arenaFloor: Int { save.arenaFloor }
    var arenaMaxFloor: Int { ArenaSystem.maxFloor }
    var arenaTier: ArenaTier { ArenaTier.tier(for: save.arenaFloor) }
    var isArenaTowerCleared: Bool { save.arenaFloor > ArenaSystem.maxFloor }

    /// Calendar-day-scoped ticket counter, same reset pattern as
    /// `ensureEnergyRefillDayCurrent`/`ensureRewardedAdDayCurrent`. Only the
    /// free daily allotment resets here — `save.arenaBonusTickets` (purchased
    /// or Battle Pass-granted) never resets, and is only ever spent, never
    /// refilled by the calendar.
    private func ensureArenaTicketDayCurrent() {
        let today = Calendar.current.startOfDay(for: Date())
        guard !Calendar.current.isDate(save.arenaTicketDay, inSameDayAs: today) else { return }
        save.arenaTicketDay = today
        save.arenaTickets = ArenaSystem.maxTicketsPerDay
    }

    var arenaTicketsRemainingToday: Int {
        ensureArenaTicketDayCurrent()
        return save.arenaTickets
    }

    /// Non-resetting balance from real-money ticket packs and Battle Pass
    /// rewards — spent only once the free daily tickets run out.
    var arenaBonusTickets: Int { save.arenaBonusTickets }

    var totalArenaTicketsAvailable: Int {
        arenaTicketsRemainingToday + arenaBonusTickets
    }

    /// A floor is unlocked once the player has reached it as their climb
    /// frontier — same "already-reached-or-current" rule as
    /// `GameState.isStageUnlocked` for the Campaign. Floors below the
    /// frontier stay unlocked forever (they're replayable for their standard
    /// reward), not just the frontier floor itself.
    func isFloorUnlocked(_ floor: Int) -> Bool {
        floor >= 1 && floor <= save.arenaFloor
    }

    /// True once `floor` has already been cleared at least once — its first-
    /// clear reward was already claimed, so fighting it again only pays the
    /// smaller standard reward.
    func isFloorCleared(_ floor: Int) -> Bool {
        floor < save.arenaFloor
    }

    /// The rival guarding `floor` — deterministic per floor (see
    /// `SeededGenerator`), so it holds steady across every read and stays
    /// the same on a retry after a loss.
    func arenaOpponent(forFloor floor: Int) -> ArenaOpponent {
        ArenaSystem.opponentForFloor(floor, catalog: catalog)
    }

    func canAffordArenaBattle() -> Bool {
        !deployedTeam.isEmpty && totalArenaTicketsAvailable > 0
    }

    /// Builds a battle against `floor`'s rival, spending a ticket up front
    /// the same way `attemptStage` spends Energy (free daily tickets first,
    /// then the non-resetting bonus balance) — the fight itself reuses the
    /// existing single-enemy `BattleEngine`/`BattleView` pipeline unchanged,
    /// with the rival's whole team represented by one elevated-stat
    /// `Combatant`. `floor` rides along on `BattleEngine.stage` so
    /// `applyArenaBattleResult` knows which floor was actually fought even
    /// though the player can now pick any unlocked floor, not just the
    /// current frontier.
    func makeArenaBattleEngine(floor: Int) -> BattleEngine? {
        ensureArenaTicketDayCurrent()
        guard !deployedTeam.isEmpty, isFloorUnlocked(floor),
              let rival = ArenaSystem.makeCombatant(for: arenaOpponent(forFloor: floor), in: catalog) else { return nil }

        let playerCombatants = makePlayerCombatants(from: deployedTeam)
        guard !playerCombatants.isEmpty, totalArenaTicketsAvailable > 0 else { return nil }
        if save.arenaTickets > 0 {
            save.arenaTickets -= 1
        } else {
            save.arenaBonusTickets -= 1
        }
        persist()
        return BattleEngine(playerUnits: playerCombatants, enemy: rival, stage: floor, isBossStage: false)
    }

    /// Applies reward changes for a finished Arena Tower fight. A win on the
    /// current frontier floor (first clear) advances the frontier and pays
    /// the bigger, fixed reward from `ArenaSystem.firstClearEquipment` —
    /// legendary-guaranteed on milestone floors. A win replaying an
    /// already-cleared floor pays the smaller, RNG-based standard reward and
    /// leaves the frontier untouched. A loss costs nothing further than the
    /// ticket already spent in `makeArenaBattleEngine` — the frontier never
    /// regresses.
    func applyArenaBattleResult(from engine: BattleEngine) -> ArenaBattleResultSummary {
        let outcome = engine.outcome ?? .defeat
        let won = outcome == .victory
        let floor = engine.stage
        let oldTier = arenaTier
        let isFirstClear = floor == save.arenaFloor
        let isMilestone = ArenaSystem.isMilestoneFloor(floor)

        var goldGained = 0
        var droppedEquipment: EquipmentItem?
        var towerCleared = false

        if won {
            incrementMission(.winBattle)

            if isFirstClear {
                goldGained = ArenaSystem.firstClearGoldReward(floor: floor)
                save.gold += goldGained
                let item = ArenaSystem.firstClearEquipment(forFloor: floor)
                save.inventory.append(item)
                droppedEquipment = item
                save.arenaFloor = floor + 1
                towerCleared = save.arenaFloor > ArenaSystem.maxFloor
            } else {
                goldGained = ArenaSystem.standardGoldReward(floor: floor)
                save.gold += goldGained
                if let item = ArenaSystem.standardEquipmentDrop(forFloor: floor) {
                    save.inventory.append(item)
                    droppedEquipment = item
                }
            }
        }

        persist()
        checkAchievements()
        let newTier = arenaTier
        return ArenaBattleResultSummary(
            outcome: outcome, floor: floor, goldGained: goldGained,
            newTier: newTier, tierChanged: newTier != oldTier,
            droppedEquipment: droppedEquipment, isFirstClear: isFirstClear,
            isMilestoneFloor: isFirstClear && isMilestone, towerCleared: towerCleared
        )
    }

    // MARK: - Stage sweep

    /// A stage can be swept once it's behind the campaign frontier — the
    /// frontier stage itself still has to be played to advance progression.
    func canSweepStage(_ stage: Int) -> Bool {
        stage >= 1 && stage < save.currentStage && !deployedTeam.isEmpty
    }

    /// Instantly re-clears an already-cleared stage for the exact same
    /// gold/account-EXP/team-EXP/equipment-drop payout as fighting it live —
    /// no `BattleEngine`, no animation. Mirrors the non-frontier-replay path
    /// of `applyBattleResult` (a stage below the frontier never advances
    /// `currentStage` or grants a boss recruit anyway, so a sweep and a
    /// replay pay out identically). Nil only when `canSweepStage` is false.
    @discardableResult
    func sweepStage(_ stage: Int) -> BattleResultSummary? {
        guard canSweepStage(stage) else { return nil }
        let isBoss = stage % World.stagesPerWorld == 0
        // Same Energy toll as fighting it live (see `attemptStage`) — a
        // Sweep is a shortcut past the animation, not past the stamina gate.
        guard spendEnergy(EnergySystem.stageCost(isBoss: isBoss)) else { return nil }
        let rewards = RewardTable.rewards(forStage: stage, isBoss: isBoss)

        save.gold += rewards.gold

        let accountBefore = save.playerLevel
        let accountResult = LevelSystem.applyExp(rewards.accountExp, level: save.playerLevel, exp: save.playerExp)
        save.playerLevel = accountResult.finalLevel
        save.playerExp = accountResult.finalExp
        let accountLevelUp = accountResult.levelsGained > 0
            ? AccountLevelUp(oldLevel: accountBefore, newLevel: accountResult.finalLevel) : nil

        var levelUps: [LevelUpSummary] = []
        for i in save.roster.indices where isDeployed(save.roster[i]) {
            guard let def = definition(for: save.roster[i]) else { continue }
            let before = save.roster[i]
            let statsBefore = before.currentStats(in: catalog, inventory: save.inventory)

            let result = LevelSystem.applyExp(rewards.expPerSurvivor, level: before.level, exp: before.exp)
            save.roster[i].level = result.finalLevel
            save.roster[i].exp = result.finalExp

            if result.levelsGained > 0 {
                let statsAfter = save.roster[i].currentStats(in: catalog, inventory: save.inventory)
                levelUps.append(LevelUpSummary(
                    name: def.name, oldLevel: before.level, newLevel: result.finalLevel,
                    statsBefore: statsBefore, statsAfter: statsAfter
                ))
            }
        }

        var droppedEquipment: EquipmentItem?
        if EquipmentFactory.shouldDrop(isBoss: isBoss) {
            let item = EquipmentFactory.randomItem(forStage: stage, isBoss: isBoss)
            save.inventory.append(item)
            droppedEquipment = item
        }

        persist()
        checkAchievements()
        return BattleResultSummary(
            outcome: .victory, stage: stage, wasBoss: isBoss,
            goldGained: rewards.gold, expGained: rewards.expPerSurvivor,
            levelUps: levelUps, newRecruit: nil, droppedEquipment: droppedEquipment,
            accountLevelUp: accountLevelUp, isPerfectClear: false, perfectClearBonusGold: 0
        )
    }

    // MARK: - Equipment

    var inventory: [EquipmentItem] { save.inventory }

    /// Items in a slot not currently worn by anyone.
    func availableItems(for slot: EquipmentSlot) -> [EquipmentItem] {
        let equippedIDs = Set(save.roster.flatMap { $0.equipped.values })
        return save.inventory.filter { $0.slot == slot && !equippedIDs.contains($0.id) }
    }

    func equippedItem(_ slot: EquipmentSlot, for instance: DreamkeeperInstance) -> EquipmentItem? {
        guard let itemID = instance.equipped[slot.rawValue] else { return nil }
        return save.inventory.first { $0.id == itemID }
    }

    func equip(_ item: EquipmentItem, to instance: DreamkeeperInstance) {
        guard let idx = save.roster.firstIndex(where: { $0.id == instance.id }) else { return }
        save.roster[idx].equipped[item.slot.rawValue] = item.id
        persist()
    }

    func unequip(_ slot: EquipmentSlot, from instance: DreamkeeperInstance) {
        guard let idx = save.roster.firstIndex(where: { $0.id == instance.id }) else { return }
        save.roster[idx].equipped.removeValue(forKey: slot.rawValue)
        persist()
    }

    func currentStats(for instance: DreamkeeperInstance) -> Stats {
        instance.currentStats(in: catalog, inventory: save.inventory)
    }

    /// Best unworn item in a slot, ranked the same way the Items tab already
    /// sorts (`InventoryView.itemsBySlot`): rarity first, then level, then
    /// the slot's own primary stat bonus.
    private func bestAvailableItem(for slot: EquipmentSlot) -> EquipmentItem? {
        availableItems(for: slot).max { a, b in
            if a.rarity != b.rarity { return a.rarity < b.rarity }
            if a.level != b.level { return a.level < b.level }
            return a.effectiveStatBonus[keyPath: slot.primaryStat] < b.effectiveStatBonus[keyPath: slot.primaryStat]
        }
    }

    private func isUpgrade(_ candidate: EquipmentItem, over current: EquipmentItem, slot: EquipmentSlot) -> Bool {
        if candidate.rarity != current.rarity { return candidate.rarity > current.rarity }
        if candidate.level != current.level { return candidate.level > current.level }
        return candidate.effectiveStatBonus[keyPath: slot.primaryStat] > current.effectiveStatBonus[keyPath: slot.primaryStat]
    }

    /// Whether `autoEquipBest` would actually change anything for `instance`
    /// right now — drives the button's disabled state so it doesn't invite
    /// a tap that does nothing.
    func canAutoEquip(_ instance: DreamkeeperInstance) -> Bool {
        for slot in EquipmentSlot.allCases {
            guard let candidate = bestAvailableItem(for: slot) else { continue }
            guard let current = equippedItem(slot, for: instance) else { return true }
            if isUpgrade(candidate, over: current, slot: slot) { return true }
        }
        return false
    }

    /// Equips the best available item into every slot at once — the one-tap
    /// alternative to picking each of the four slots by hand. Only ever
    /// fills an empty slot or upgrades one that's strictly worse (never
    /// removes or downgrades), and only draws from unworn inventory so it
    /// can never strip gear off another deployed Dreamkeeper.
    @discardableResult
    func autoEquipBest(for instance: DreamkeeperInstance) -> Bool {
        guard let idx = save.roster.firstIndex(where: { $0.id == instance.id }) else { return false }
        var changed = false
        for slot in EquipmentSlot.allCases {
            guard let candidate = bestAvailableItem(for: slot) else { continue }
            if let current = equippedItem(slot, for: save.roster[idx]), !isUpgrade(candidate, over: current, slot: slot) {
                continue
            }
            save.roster[idx].equipped[slot.rawValue] = candidate.id
            changed = true
        }
        if changed { persist() }
        return changed
    }

    /// Which Dreamkeeper (if any) currently has this item equipped — shown
    /// in the item detail sheet so upgrading gear reads as improving a teammate.
    func wearer(of item: EquipmentItem) -> DreamkeeperInstance? {
        save.roster.first { $0.equipped[item.slot.rawValue] == item.id }
    }

    /// Spends gold to raise an item's level in place (same id, so any
    /// equipped reference to it stays valid). Returns false if the item is
    /// missing, already maxed, or the player can't afford it.
    @discardableResult
    func upgradeEquipment(_ item: EquipmentItem) -> Bool {
        guard let idx = save.inventory.firstIndex(where: { $0.id == item.id }),
              EquipmentUpgrade.canUpgrade(item) else { return false }
        let cost = EquipmentUpgrade.cost(for: item)
        guard save.gold >= cost else { return false }

        save.gold -= cost
        save.inventory[idx] = EquipmentUpgrade.upgraded(item)
        incrementMission(.upgradeEquipment)
        incrementWeeklyMission(.upgradeEquipment)
        persist()
        return true
    }

    // MARK: - Equipment star fusion

    /// Other owned items of the same kind as `target` (same slot, name,
    /// rarity) — fusion fodder, picked manually just like Dreamkeeper fusion.
    func duplicates(ofItem target: EquipmentItem) -> [EquipmentItem] {
        save.inventory.filter { $0.id != target.id && $0.isSameKind(as: target) }
    }

    /// Duplicates required for `target`'s next star tier, or nil if already maxed.
    func nextFusionCost(forItem target: EquipmentItem) -> Int? {
        guard target.stars < StarFusionSystem.maxStars else { return nil }
        return StarFusionSystem.duplicatesRequired(forTier: target.stars + 1)
    }

    /// `selected` just needs to be one or more real duplicates of `target`
    /// currently in the inventory, with no repeats — a fuse no longer has
    /// to hand over an exact tier's cost in one go (see `fuseItem`).
    func canFuseItem(_ target: EquipmentItem, consuming selected: [EquipmentItem]) -> Bool {
        guard target.stars < StarFusionSystem.maxStars, !selected.isEmpty else { return false }
        let selectedIDs = Set(selected.map(\.id))
        guard selectedIDs.count == selected.count, !selectedIDs.contains(target.id) else { return false }
        let validDuplicateIDs = Set(duplicates(ofItem: target).map(\.id))
        return selectedIDs.isSubset(of: validDuplicateIDs)
    }

    /// Deletes `selected` from the inventory (unequipping them first if
    /// worn), then banks their count onto `target.fusionProgress`, resolving
    /// as many star tier-ups as the combined total supports — same banked-
    /// progress model as `fuseDreamkeeper`. Returns false (no change) if
    /// `selected` isn't a valid, non-empty set of `target`'s duplicates —
    /// the UI should gate the fuse button on `canFuseItem` so this is a
    /// safety net.
    @discardableResult
    func fuseItem(_ target: EquipmentItem, consuming selected: [EquipmentItem]) -> Bool {
        guard canFuseItem(target, consuming: selected) else { return false }
        let selectedIDs = Set(selected.map(\.id))
        for i in save.roster.indices {
            for (slotKey, itemID) in save.roster[i].equipped where selectedIDs.contains(itemID) {
                save.roster[i].equipped.removeValue(forKey: slotKey)
            }
        }
        save.inventory.removeAll { selectedIDs.contains($0.id) }
        guard let idx = save.inventory.firstIndex(where: { $0.id == target.id }) else { return false }
        let result = StarFusionSystem.applyFusion(
            newDuplicates: selected.count, stars: save.inventory[idx].stars, progress: save.inventory[idx].fusionProgress
        )
        save.inventory[idx].stars = result.stars
        save.inventory[idx].fusionProgress = result.progress
        persist()
        return true
    }

    // MARK: - Summon pity

    /// Exposed for the Summoning Shrine's odds card, so pity progress is
    /// visible rather than a hidden mechanic.
    var pullsSinceEpicSummon: Int { save.pullsSinceEpicSummon }
    var pullsSinceLegendarySummon: Int { save.pullsSinceLegendarySummon }

    /// Rolls one pity-aware rarity and updates both counters from the
    /// result — the single roll path shared by Dreamkeeper and Equipment
    /// Summoning so the pity clock is one dial (see `SummonSystem.rollRarity(pullsSinceEpic:pullsSinceLegendary:)`).
    /// A Legendary+ result resets both counters (it also satisfies the Epic
    /// pity); an Epic result resets only the Epic counter.
    private func nextPitySummonRarity(roll: Double = .random(in: 0..<1)) -> Rarity {
        let rarity = SummonSystem.rollRarity(pullsSinceEpic: save.pullsSinceEpicSummon, pullsSinceLegendary: save.pullsSinceLegendarySummon, roll: roll)
        if rarity >= .legendary {
            save.pullsSinceEpicSummon = 0
            save.pullsSinceLegendarySummon = 0
        } else if rarity >= .epic {
            save.pullsSinceEpicSummon = 0
            save.pullsSinceLegendarySummon += 1
        } else {
            save.pullsSinceEpicSummon += 1
            save.pullsSinceLegendarySummon += 1
        }
        return rarity
    }

    // MARK: - Summoning

    var canAffordSummon: Bool { save.dreamGems >= SummonSystem.cost }
    var canAffordMultiSummon: Bool { save.dreamGems >= SummonSystem.multiPullCost }

    /// Rolls one pull and lands it in the roster — including duplicates,
    /// which sit benched as fusion fodder for a later manual fusion (see
    /// MARK: - Star fusion) rather than auto-converting. Gems and mission
    /// progress are the caller's responsibility so a multi-pull can batch
    /// them once instead of per-roll. `minimumRarity`, when set, raises a
    /// below-floor roll to it — used only for the one-time Beginner's
    /// Banner guarantee (see `performMultiSummon`). `roll`, like
    /// `SummonSystem.rollRarity(roll:)`, defaults to random and exists so
    /// tests can force a specific rarity band deterministically.
    func rollAndAddSummon(minimumRarity: Rarity? = nil, roll: Double = .random(in: 0..<1)) -> SummonResult {
        var rarity = nextPitySummonRarity(roll: roll)
        if let minimumRarity, rarity < minimumRarity {
            rarity = minimumRarity
        }
        // `.exclusive` (Igo/Ames) has no dupes and is always granted at max
        // level/stars — once both are owned the tier is unreachable, so a
        // roll that lands there quietly becomes a `.mythic` pull instead of
        // wasting it on an impossible duplicate. See `TwinBond`.
        var unownedExclusive: [DreamkeeperDefinition] = []
        if rarity == .exclusive {
            let ownedIDs = Set(save.roster.map(\.definitionID))
            unownedExclusive = catalog.definitions.filter { $0.rarity == .exclusive && !ownedIDs.contains($0.id) }
            if unownedExclusive.isEmpty {
                rarity = .mythic
            }
        }
        let definition = rarity == .exclusive ? unownedExclusive.randomElement()! : SummonSystem.rollDefinition(from: catalog, rarity: rarity)
        let isNew = !save.roster.contains { $0.definitionID == definition.id }
        let instance = rarity == .exclusive
            ? DreamkeeperInstance(definitionID: definition.id, level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars)
            : DreamkeeperInstance(definitionID: definition.id)
        save.roster.append(instance)
        if isNew, save.teams[activeTeamIndex].memberIDs.count < Team.maxSize {
            save.teams[activeTeamIndex].memberIDs.append(instance.id)
        }
        return SummonResult(definition: definition, isNew: isNew)
    }

    /// Returns nil only when the player can't afford it — the UI should keep
    /// the button disabled via `canAffordSummon` so this is a safety net.
    @discardableResult
    func performSummon() -> SummonResult? {
        guard canAffordSummon else { return nil }
        save.dreamGems -= SummonSystem.cost
        let result = rollAndAddSummon()
        incrementMission(.performSummon)
        incrementMission(.premiumBonusSummons)
        incrementWeeklyMission(.performSummons)
        persist()
        checkAchievements()
        return result
    }

    /// Pays for `SummonSystem.multiPullPaidCount` pulls and returns
    /// `SummonSystem.multiPullTotalCount` results — the "10+1 free" bundle.
    /// Nil only when the player can't afford it. The very first multi-pull
    /// the player ever makes (Dreamkeeper or Equipment) is a "Beginner's
    /// Banner": every roll in it is floored at Uncommon, so a new player's
    /// first big pull can't come back all-Common.
    @discardableResult
    func performMultiSummon() -> [SummonResult]? {
        guard canAffordMultiSummon else { return nil }
        save.dreamGems -= SummonSystem.multiPullCost
        let isBeginnerPull = !save.hasUsedBeginnerMultiSummon
        let results = (0..<SummonSystem.multiPullTotalCount).map { _ in
            rollAndAddSummon(minimumRarity: isBeginnerPull ? .uncommon : nil)
        }
        save.hasUsedBeginnerMultiSummon = true
        incrementMission(.performSummon, by: results.count)
        incrementMission(.premiumBonusSummons, by: results.count)
        incrementWeeklyMission(.performSummons, by: results.count)
        persist()
        checkAchievements()
        return results
    }

    // MARK: - Equipment Summoning

    var canAffordEquipmentSummon: Bool { save.dreamGems >= EquipmentSummonSystem.cost }
    var canAffordEquipmentMultiSummon: Bool { save.dreamGems >= EquipmentSummonSystem.multiPullCost }

    /// Rolls one item at the player's current stage and drops it straight
    /// into the inventory — mirrors `rollAndAddSummon` above, but no
    /// mission/achievement bookkeeping here since the existing summon
    /// missions ("Summon a Dreamkeeper", etc.) are worded for Dreamkeeper
    /// pulls specifically and would misreport an equipment pull.
    private func rollAndAddEquipmentSummon(minimumRarity: Rarity? = nil) -> EquipmentItem {
        var rarity = nextPitySummonRarity()
        if let minimumRarity, rarity < minimumRarity {
            rarity = minimumRarity
        }
        let item = EquipmentSummonSystem.rollItem(forStage: save.currentStage, rarity: rarity)
        save.inventory.append(item)
        return item
    }

    /// Returns nil only when the player can't afford it — the UI should keep
    /// the button disabled via `canAffordEquipmentSummon` so this is a safety net.
    @discardableResult
    func performEquipmentSummon() -> EquipmentItem? {
        guard canAffordEquipmentSummon else { return nil }
        save.dreamGems -= EquipmentSummonSystem.cost
        let result = rollAndAddEquipmentSummon()
        persist()
        checkAchievements()
        return result
    }

    /// Pays for `EquipmentSummonSystem.multiPullPaidCount` pulls and returns
    /// `EquipmentSummonSystem.multiPullTotalCount` results — the "10+1 free"
    /// bundle. Nil only when the player can't afford it. Shares the same
    /// one-time Beginner's Banner guarantee as `performMultiSummon` — see
    /// its doc comment.
    @discardableResult
    func performEquipmentMultiSummon() -> [EquipmentItem]? {
        guard canAffordEquipmentMultiSummon else { return nil }
        save.dreamGems -= EquipmentSummonSystem.multiPullCost
        let isBeginnerPull = !save.hasUsedBeginnerMultiSummon
        let results = (0..<EquipmentSummonSystem.multiPullTotalCount).map { _ in
            rollAndAddEquipmentSummon(minimumRarity: isBeginnerPull ? .uncommon : nil)
        }
        save.hasUsedBeginnerMultiSummon = true
        persist()
        checkAchievements()
        return results
    }

    // MARK: - Offline buildings

    var pendingGoldFountainReward: Int {
        OfflineRewards.pendingGold(since: save.lastGoldCollectedAt)
    }

    var pendingTrainingGardenReward: Int {
        OfflineRewards.pendingExp(since: save.lastTrainingCollectedAt)
    }

    @discardableResult
    func collectGoldFountain() -> Int {
        let amount = pendingGoldFountainReward
        guard amount > 0 else { return 0 }
        save.gold += amount
        save.lastGoldCollectedAt = Date()
        incrementMission(.collectBuilding)
        persist()
        if save.notificationsEnabled {
            scheduleGoldFountainNotification()
        }
        return amount
    }

    struct TrainingResult: Equatable {
        var expGranted: Int
        var levelUps: [LevelUpSummary]
    }

    /// Grants the accrued EXP to every deployed Dreamkeeper (same rate each,
    /// mirroring how battle rewards pay every survivor). Requires a deployed
    /// team so the EXP has someone to go to.
    @discardableResult
    func collectTrainingGarden() -> TrainingResult? {
        let amount = pendingTrainingGardenReward
        guard amount > 0, !deployedTeam.isEmpty else { return nil }

        var levelUps: [LevelUpSummary] = []
        for i in save.roster.indices where isDeployed(save.roster[i]) {
            guard let def = definition(for: save.roster[i]) else { continue }
            let before = save.roster[i]
            let statsBefore = before.currentStats(in: catalog, inventory: save.inventory)

            let result = LevelSystem.applyExp(amount, level: before.level, exp: before.exp)
            save.roster[i].level = result.finalLevel
            save.roster[i].exp = result.finalExp

            if result.levelsGained > 0 {
                let statsAfter = save.roster[i].currentStats(in: catalog, inventory: save.inventory)
                levelUps.append(LevelUpSummary(
                    name: def.name, oldLevel: before.level, newLevel: result.finalLevel,
                    statsBefore: statsBefore, statsAfter: statsAfter
                ))
            }
        }

        save.lastTrainingCollectedAt = Date()
        incrementMission(.collectBuilding)
        persist()
        if save.notificationsEnabled {
            scheduleTrainingGardenNotification()
        }
        return TrainingResult(expGranted: amount, levelUps: levelUps)
    }

    // MARK: - Daily Missions

    struct MissionStatus: Identifiable {
        var definition: MissionDefinition
        var progress: Int
        var isClaimed: Bool
        var isLocked: Bool

        var id: MissionID { definition.id }
        var isComplete: Bool { progress >= definition.target }
    }

    /// Today's board: every Premium bonus mission (always shown, locked
    /// until Premium is unlocked) plus whichever free-tier missions today's
    /// draw selected — never the full 7-mission pool at once, see
    /// `DailyMissions.drawDaily`.
    var dailyMissions: [MissionStatus] {
        ensureMissionsCurrent()
        let selected = Set(save.dailyMissionSelectedIDs)
        return DailyMissions.definitions
            .filter { $0.isPremiumOnly || selected.contains($0.id.rawValue) }
            .map { def in
                MissionStatus(
                    definition: def,
                    progress: min(def.target, save.dailyMissionProgress[def.id.rawValue] ?? 0),
                    isClaimed: save.claimedMissionIDs.contains(def.id.rawValue),
                    isLocked: def.isPremiumOnly && !battlePassPremiumUnlocked
                )
            }
    }

    var hasUnclaimedMissions: Bool {
        dailyMissions.contains { $0.isComplete && !$0.isClaimed && !$0.isLocked } || hasUnclaimedWeeklyMissions
    }

    @discardableResult
    func claimMission(_ id: MissionID) -> Bool {
        ensureMissionsCurrent()
        guard let def = DailyMissions.definitions.first(where: { $0.id == id }),
              !def.isPremiumOnly || battlePassPremiumUnlocked,
              (save.dailyMissionProgress[id.rawValue] ?? 0) >= def.target,
              !save.claimedMissionIDs.contains(id.rawValue) else { return false }

        save.gold += def.goldReward
        save.dreamGems += def.gemReward
        grantEnergy(def.energyReward)
        save.claimedMissionIDs.insert(id.rawValue)
        persist()
        return true
    }

    private func incrementMission(_ id: MissionID, by amount: Int = 1) {
        ensureMissionsCurrent()
        guard let def = DailyMissions.definitions.first(where: { $0.id == id }) else { return }
        let current = save.dailyMissionProgress[id.rawValue] ?? 0
        save.dailyMissionProgress[id.rawValue] = min(def.target, current + amount)
    }

    /// Missions and claims are scoped to a calendar day; once the stored day
    /// no longer matches today, both reset (so yesterday's progress can't
    /// carry over or be claimed twice) and a fresh set of free-tier missions
    /// is drawn for the new day. A save that already has today's date but an
    /// empty selection (pre-rotation save, migrated mid-day) only gets a
    /// draw — its in-progress missions aren't wiped just to backfill a field.
    private func ensureMissionsCurrent() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(save.dailyMissionDay, inSameDayAs: today) {
            save.dailyMissionDay = today
            save.dailyMissionProgress = [:]
            save.claimedMissionIDs = []
            save.dailyMissionSelectedIDs = DailyMissions.drawDaily()
            persist()
        } else if save.dailyMissionSelectedIDs.isEmpty {
            save.dailyMissionSelectedIDs = DailyMissions.drawDaily()
            persist()
        }
    }

    // MARK: - Weekly Missions (Battle Pass Premium)

    struct WeeklyMissionStatus: Identifiable {
        var definition: WeeklyMissionDefinition
        var progress: Int
        var isClaimed: Bool

        var id: WeeklyMissionID { definition.id }
        var isComplete: Bool { progress >= definition.target }
    }

    var weeklyMissions: [WeeklyMissionStatus] {
        ensureWeeklyMissionsCurrent()
        return WeeklyMissions.definitions.map { def in
            WeeklyMissionStatus(
                definition: def,
                progress: min(def.target, save.weeklyMissionProgress[def.id.rawValue] ?? 0),
                isClaimed: save.claimedWeeklyMissionIDs.contains(def.id.rawValue)
            )
        }
    }

    var hasUnclaimedWeeklyMissions: Bool {
        guard battlePassPremiumUnlocked else { return false }
        return weeklyMissions.contains { $0.isComplete && !$0.isClaimed }
    }

    @discardableResult
    func claimWeeklyMission(_ id: WeeklyMissionID) -> Bool {
        ensureWeeklyMissionsCurrent()
        guard battlePassPremiumUnlocked,
              let def = WeeklyMissions.definitions.first(where: { $0.id == id }),
              (save.weeklyMissionProgress[id.rawValue] ?? 0) >= def.target,
              !save.claimedWeeklyMissionIDs.contains(id.rawValue) else { return false }

        save.gold += def.goldReward
        save.dreamGems += def.gemReward
        grantEnergy(def.energyReward)
        save.claimedWeeklyMissionIDs.insert(id.rawValue)
        persist()
        return true
    }

    private func incrementWeeklyMission(_ id: WeeklyMissionID, by amount: Int = 1) {
        ensureWeeklyMissionsCurrent()
        guard let def = WeeklyMissions.definitions.first(where: { $0.id == id }) else { return }
        let current = save.weeklyMissionProgress[id.rawValue] ?? 0
        save.weeklyMissionProgress[id.rawValue] = min(def.target, current + amount)
    }

    /// Weekly missions reset on a calendar-week boundary rather than daily —
    /// tracked separately from `dailyMissionDay` so a Monday reset doesn't
    /// also wipe same-day daily progress.
    private func ensureWeeklyMissionsCurrent() {
        let thisWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        guard !Calendar.current.isDate(save.weeklyMissionWeek, equalTo: thisWeek, toGranularity: .weekOfYear) else { return }
        save.weeklyMissionWeek = thisWeek
        save.weeklyMissionProgress = [:]
        save.claimedWeeklyMissionIDs = []
        persist()
    }

    // MARK: - Shop

    func isPurchased(_ item: ShopItem) -> Bool {
        save.purchasedOneTimeOfferIDs.contains(item.id)
    }

    func canPurchase(_ item: ShopItem) -> Bool {
        switch item.kind {
        case .gemPack, .arenaTicketPack:
            return true
        case .starterPack, .vip:
            return !isPurchased(item)
        case .exclusiveCharacter:
            // Also block if the character was already obtained through the
            // Summoning Shrine's `.exclusive` gacha path — `isPurchased`
            // alone only tracks the shop's own one-time-offer history, so
            // without this check a player who already gacha'd Igo/Ames could
            // still pay real money for a second, permanently unsellable and
            // unfusable copy (see `rollAndAddSummon`'s "no dupes" comment).
            guard !isPurchased(item) else { return false }
            guard let definitionID = item.grantsDefinitionID else { return true }
            return !save.roster.contains { $0.definitionID == definitionID }
        case .goldExchange:
            return save.dreamGems >= item.gemCost
        }
    }

    /// Grants an item's rewards unconditionally once `canPurchase` passes —
    /// this is the *grant* step only and never itself charges real money, by
    /// design, so it stays directly unit-testable with no StoreKit
    /// involved. Every real-money item (everything but `.goldExchange`) must
    /// be charged via `purchaseWithRealMoney(_:)` first, which calls this
    /// only after a verified StoreKit transaction. Gold exchanges are a real
    /// in-game soft-currency sink and always work this way, in the shipped
    /// app too. Arena tickets are deliberately real-money only: nothing here
    /// ever grants `arenaBonusTickets` from a gold- or gem-costing item.
    @discardableResult
    func purchase(_ item: ShopItem) -> Bool {
        guard canPurchase(item) else { return false }

        if item.kind == .goldExchange {
            save.dreamGems -= item.gemCost
        }
        save.gold += item.goldGranted
        save.dreamGems += item.gemsGranted
        if item.kind == .arenaTicketPack {
            save.arenaBonusTickets += item.ticketsGranted
        }
        if item.kind == .starterPack || item.kind == .vip || item.kind == .exclusiveCharacter {
            save.purchasedOneTimeOfferIDs.insert(item.id)
        }
        if item.kind == .vip {
            save.isVIP = true
        }
        if item.kind == .exclusiveCharacter, let definitionID = item.grantsDefinitionID {
            save.roster.append(DreamkeeperInstance(definitionID: definitionID, level: LevelSystem.maxLevel, stars: StarFusionSystem.maxStars))
        }

        incrementMission(.spendInShop)
        incrementWeeklyMission(.visitShop)
        persist()
        return true
    }

    /// The real entry point for every real-money `ShopItem` (any item with a
    /// non-nil `productID`) — charges through `purchaseService` first and
    /// only calls `purchase(_:)` to grant the reward once StoreKit reports a
    /// verified transaction. Items with a nil `productID` (only
    /// `.goldExchange` today) skip the charge entirely and grant directly,
    /// same as calling `purchase(_:)` itself.
    @MainActor
    @discardableResult
    func purchaseWithRealMoney(_ item: ShopItem) async -> Bool {
        guard item.productID != nil else { return purchase(item) }
        guard canPurchase(item) else { return false }
        let outcome = await purchaseService.purchase(item)
        guard outcome == .success else { return false }
        return purchase(item)
    }

    // MARK: - Rewarded ads

    static let maxRewardedAdsPerDay = 3
    static let rewardedAdGold = 80
    static let rewardedAdGems = 5

    var isVIP: Bool { save.isVIP }

    /// Rewarded-ad watches are scoped to a calendar day; once the stored day
    /// no longer matches today, the count resets — same pattern as
    /// `ensureMissionsCurrent`.
    private func ensureRewardedAdDayCurrent() {
        let today = Calendar.current.startOfDay(for: Date())
        guard !Calendar.current.isDate(save.rewardedAdWatchDay, inSameDayAs: today) else { return }
        save.rewardedAdWatchDay = today
        save.rewardedAdWatchCount = 0
    }

    var rewardedAdWatchesRemainingToday: Int {
        ensureRewardedAdDayCurrent()
        return max(0, Self.maxRewardedAdsPerDay - save.rewardedAdWatchCount)
    }

    /// True while the daily cap hasn't been hit and the player hasn't gone
    /// VIP — VIP's whole point is never seeing this prompt again.
    var isRewardedAdAvailable: Bool {
        !save.isVIP && rewardedAdWatchesRemainingToday > 0
    }

    /// Presents a rewarded ad through `adService` and grants a fixed
    /// Gold+Gems bonus if the viewer watches it through. A skipped/failed ad
    /// doesn't burn a watch — only a completed view does, so declining once
    /// just means trying again immediately rather than losing the slot.
    @MainActor
    @discardableResult
    func watchRewardedAd() async -> Bool {
        guard isRewardedAdAvailable else { return false }
        let rewarded = await adService.showRewardedAd()
        if rewarded {
            save.gold += Self.rewardedAdGold
            save.dreamGems += Self.rewardedAdGems
            save.rewardedAdWatchCount += 1
            save.lastRewardedAdClaimedAt = Date()
            persist()
        }
        return rewarded
    }

    // MARK: - Interstitial ads

    /// Stages between automatic interstitials, and the minimum real time
    /// that must also have passed — both have to be satisfied, so a player
    /// who blitzes through stages doesn't see back-to-back interstitials.
    static let stagesPerInterstitial = 2
    static let minSecondsBetweenInterstitials: TimeInterval = 2 * 60

    /// True once both the stage-count and time pacing floors are clear and
    /// the player hasn't gone VIP. `RootView` checks this right after a
    /// battle result is dismissed and presents `InterstitialAdSheet` if so.
    var shouldShowInterstitial: Bool {
        !save.isVIP
            && save.stagesSinceLastInterstitial >= Self.stagesPerInterstitial
            && Date().timeIntervalSince(save.lastInterstitialShownAt) >= Self.minSecondsBetweenInterstitials
    }

    /// Called once per completed stage (see `applyBattleResult`) — tracks
    /// progress toward the next automatic interstitial.
    private func recordStageForInterstitialPacing() {
        save.stagesSinceLastInterstitial += 1
    }

    /// Resets both pacing counters — called the moment an interstitial is
    /// *attempted*, whether or not it actually filled, so a no-fill doesn't
    /// cause a retry on every single subsequent stage.
    private func markInterstitialAttempted() {
        save.stagesSinceLastInterstitial = 0
        save.lastInterstitialShownAt = Date()
        persist()
    }

    @MainActor
    func showInterstitialAd() async {
        markInterstitialAttempted()
        await interstitialAdService.showInterstitialAd()
    }

    private func grantNextRecruitIfAvailable() -> DreamkeeperDefinition? {
        let owned = Set(save.roster.map(\.definitionID))
        guard let nextID = DreamkeeperCatalog.unlockOrder.first(where: { !owned.contains($0) }),
              let def = catalog.definition(for: nextID) else { return nil }

        let instance = DreamkeeperInstance(definitionID: nextID)
        save.roster.append(instance)
        if save.teams[activeTeamIndex].memberIDs.count < Team.maxSize {
            save.teams[activeTeamIndex].memberIDs.append(instance.id)
        }
        return def
    }

    func playHaptic(_ style: HapticStyle) {
        if save.hapticsEnabled {
            platform.playHaptic(style)
        }
        if let effect = style.pairedSoundEffect {
            playSound(effect)
        }
    }

    func playSound(_ effect: SoundEffect) {
        guard save.soundEnabled else { return }
        platform.playSound(effect)
    }

    // MARK: - Bestiary (Dream Observatory)

    /// Every monster/boss the player has encountered at least once, keyed by
    /// name — populated from `applyBattleResult` regardless of outcome, so a
    /// loss still reveals what was fought.
    func isDiscovered(_ monsterName: String) -> Bool {
        save.discoveredMonsters.contains(monsterName)
    }

    var bestiaryDiscoveredCount: Int {
        WorldCatalog.worlds.reduce(into: 0) { count, world in
            count += MonsterCatalog.allEntries(forWorld: world.id).filter { isDiscovered($0.name) }.count
        }
    }

    var bestiaryTotalCount: Int {
        WorldCatalog.worlds.reduce(0) { $0 + MonsterCatalog.allEntries(forWorld: $1.id).count }
    }

    // MARK: - Battle Pass

    var battlePassTier: Int { BattlePassSystem.tier(forXP: save.battlePassXP) }
    var battlePassProgress: (current: Int, needed: Int) { BattlePassSystem.progressWithinTier(forXP: save.battlePassXP) }
    var battlePassPremiumUnlocked: Bool { save.battlePassPremiumUnlocked }

    private func battlePassRewardID(tier: Int, premium: Bool) -> String {
        "\(tier)-\(premium ? "premium" : "free")"
    }

    func isBattlePassRewardClaimed(tier: Int, premium: Bool) -> Bool {
        save.claimedBattlePassRewardIDs.contains(battlePassRewardID(tier: tier, premium: premium))
    }

    func canClaimBattlePassReward(tier: Int, premium: Bool) -> Bool {
        guard tier >= 1, tier <= battlePassTier else { return false }
        guard !premium || battlePassPremiumUnlocked else { return false }
        return !isBattlePassRewardClaimed(tier: tier, premium: premium)
    }

    /// Any reachable, unclaimed reward on either track — drives the Dream
    /// Haven header badge, mirroring `hasUnclaimedMissions`.
    var hasUnclaimedBattlePassRewards: Bool {
        guard battlePassTier >= 1 else { return false }
        return (1...battlePassTier).contains { tier in
            canClaimBattlePassReward(tier: tier, premium: false) || canClaimBattlePassReward(tier: tier, premium: true)
        }
    }

    @discardableResult
    func claimBattlePassReward(tier: Int, premium: Bool) -> Bool {
        guard canClaimBattlePassReward(tier: tier, premium: premium) else { return false }
        let reward = premium ? BattlePassSystem.premiumReward(forTier: tier) : BattlePassSystem.freeReward(forTier: tier)
        save.gold += reward.gold
        save.dreamGems += reward.gems
        save.arenaBonusTickets += reward.tickets
        save.claimedBattlePassRewardIDs.insert(battlePassRewardID(tier: tier, premium: premium))
        persist()
        return true
    }

    /// Placeholder real-money unlock, same "grant directly, no charge" MVP
    /// pattern as `ShopItemKind.gemPack` — swap in a real StoreKit 2
    /// transaction later without touching callers.
    @discardableResult
    func purchaseBattlePassPremium() -> Bool {
        guard !battlePassPremiumUnlocked else { return false }
        save.battlePassPremiumUnlocked = true
        persist()
        return true
    }

    // MARK: - Settings

    var hapticsEnabled: Bool { save.hapticsEnabled }

    func setHapticsEnabled(_ enabled: Bool) {
        save.hapticsEnabled = enabled
        persist()
    }

    var soundEnabled: Bool { save.soundEnabled }

    func setSoundEnabled(_ enabled: Bool) {
        save.soundEnabled = enabled
        persist()
    }

    /// 1.0 or 2.0 — read by `BattleEngine.tick(dt:)` callers to scale the
    /// tick rate. Persisted so the player's chosen pace carries into the
    /// next battle instead of resetting every fight.
    var battleSpeedMultiplier: Double { save.battleSpeedMultiplier }

    func setBattleSpeedMultiplier(_ multiplier: Double) {
        save.battleSpeedMultiplier = multiplier
        persist()
    }

    /// When on, `BattleView` fires each ready Dreamkeeper's Active Skill and
    /// Ultimate automatically every tick instead of waiting for a tap.
    var autoBattleEnabled: Bool { save.autoBattleEnabled }

    func setAutoBattleEnabled(_ enabled: Bool) {
        save.autoBattleEnabled = enabled
        persist()
    }

    /// nil means "follow the device's system language" — explicitly picking
    /// German or English overrides that for the whole app via `.environment(\.locale:)`.
    var preferredLanguage: String? { save.preferredLanguage }

    var preferredLocale: Locale {
        guard let preferredLanguage else { return .autoupdatingCurrent }
        return Locale(identifier: preferredLanguage)
    }

    func setPreferredLanguage(_ languageCode: String?) {
        save.preferredLanguage = languageCode
        persist()
    }

    // MARK: - Notifications

    private static let goldFountainNotificationID = "dk.notif.goldFountain"
    private static let trainingGardenNotificationID = "dk.notif.trainingGarden"
    private static let dailyMissionsNotificationID = "dk.notif.dailyMissions"
    private static let loginRewardNotificationID = "dk.notif.loginReward"

    var notificationsEnabled: Bool { save.notificationsEnabled }

    /// Turning this on requests OS permission (a no-op if already granted or
    /// denied) and, only once actually authorized, arms both building
    /// reminders and the daily missions nudge. Turning it off cancels
    /// everything immediately — no dangling reminders after opting out.
    /// `completion` reports whether notifications ended up enabled (`false`
    /// if the player declined the system prompt), so the Settings toggle can
    /// snap back instead of showing a state that isn't actually in effect.
    func setNotificationsEnabled(_ enabled: Bool, completion: @escaping (Bool) -> Void = { _ in }) {
        guard enabled else {
            save.notificationsEnabled = false
            persist()
            platform.cancelAllNotifications()
            completion(false)
            return
        }
        platform.requestNotificationAuthorization { [weak self] granted in
            guard let self else { return }
            self.save.notificationsEnabled = granted
            self.persist()
            if granted {
                self.scheduleBuildingNotifications()
                self.platform.scheduleDailyNotification(
                    id: Self.dailyMissionsNotificationID,
                    title: self.notificationText(en: "Daily Missions", de: "Tägliche Missionen"),
                    body: self.notificationText(
                        en: "New daily missions are ready in Dream Haven.",
                        de: "Neue tägliche Missionen warten im Traumhafen."
                    ),
                    hour: 18, minute: 0
                )
                self.platform.scheduleDailyNotification(
                    id: Self.loginRewardNotificationID,
                    title: self.notificationText(en: "Daily Login Bonus", de: "Tägliche Login-Belohnung"),
                    body: self.notificationText(
                        en: "Your login streak reward is waiting in Dream Haven.",
                        de: "Deine Login-Streak-Belohnung wartet im Traumhafen."
                    ),
                    hour: 10, minute: 0
                )
            }
            completion(granted)
        }
    }

    private func scheduleBuildingNotifications() {
        scheduleGoldFountainNotification()
        scheduleTrainingGardenNotification()
    }

    private func scheduleGoldFountainNotification() {
        platform.scheduleNotification(
            id: Self.goldFountainNotificationID,
            title: notificationText(en: "Gold Fountain is full!", de: "Der Goldbrunnen ist voll!"),
            body: notificationText(
                en: "Come collect your gold before it caps out.",
                de: "Hol dir dein Gold ab, bevor es überläuft."
            ),
            fireDate: save.lastGoldCollectedAt.addingTimeInterval(OfflineRewards.maxAccrualSeconds)
        )
    }

    private func scheduleTrainingGardenNotification() {
        platform.scheduleNotification(
            id: Self.trainingGardenNotificationID,
            title: notificationText(en: "Training Garden is full!", de: "Der Trainingsgarten ist voll!"),
            body: notificationText(
                en: "Your team has EXP waiting to be collected.",
                de: "Dein Team hat EP, die abgeholt werden können."
            ),
            fireDate: save.lastTrainingCollectedAt.addingTimeInterval(OfflineRewards.maxAccrualSeconds)
        )
    }

    /// Local notifications are scheduled through `UNUserNotificationCenter`
    /// outside any SwiftUI view, so they can't pick up `Localizable.xcstrings`
    /// via `Text`/`LocalizedStringKey` the way on-screen copy does — this
    /// picks between two hand-supplied strings using the same preference
    /// `preferredLocale` already exposes to the rest of the app.
    private func notificationText(en: String, de: String) -> String {
        preferredLocale.language.languageCode?.identifier == "de" ? de : en
    }

    // MARK: - Onboarding

    var hasSeenOnboarding: Bool { save.hasSeenOnboarding }

    func completeOnboarding() {
        save.hasSeenOnboarding = true
        persist()
    }

    /// True while the player hasn't locked in the starter Olf's element yet
    /// — i.e. the post-onboarding "choose Olf's element" screen still needs
    /// to run. Backed by `GameSave.hasChosenStarterElement` rather than a
    /// `definitionID` identity check: `DreamkeeperCatalog.olfDefinitionID(for: .ember)`
    /// equals `DreamkeeperCatalog.starterOlfDefaultID` itself, so comparing
    /// against the placeholder id would make choosing Ember a silent no-op
    /// and reopen this screen on every visit to Dream Haven forever.
    var needsStarterOlfChoice: Bool {
        !save.hasChosenStarterElement
    }

    /// Locks in the starter Olf's element — or, when `element` is `nil`
    /// (the secret 5-second hold on Ember), grants Ultimate Olf instead.
    /// Swaps the *same* roster instance's `definitionID` in place, so its
    /// level/exp/equipped gear carry over untouched, and sets
    /// `hasChosenStarterElement` unconditionally so the choice never
    /// resurfaces — regardless of which element (even Ember) was picked. A
    /// no-op once already chosen (or on an old save with no placeholder
    /// starter to resolve).
    @discardableResult
    func chooseStarterOlf(element: Element?) -> Bool {
        guard !save.hasChosenStarterElement else { return false }
        if let index = save.roster.firstIndex(where: { $0.definitionID == DreamkeeperCatalog.starterOlfDefaultID }) {
            save.roster[index].definitionID = element.map(DreamkeeperCatalog.olfDefinitionID(for:)) ?? DreamkeeperCatalog.ultimateOlfID
        }
        save.hasChosenStarterElement = true
        persist()
        return true
    }

    /// Wipes all progress and starts over from a fresh save. Irreversible —
    /// the UI must confirm with the player before calling this.
    func resetProgress() {
        save = .newGame(starterDefinitionID: DreamkeeperCatalog.starterOlfDefaultID)
        selectedStage = 1
        persist()
        platform.cancelAllNotifications()
    }

    /// QA-only: drops a sample item of every slot into the inventory so the
    /// equip UI can be exercised without playing through a battle first.
    /// Only invoked when `DK_SEED_ITEM` is set — no effect in normal play.
    func debugSeedInventory() {
        for _ in EquipmentSlot.allCases {
            save.inventory.append(EquipmentFactory.randomItem(forStage: 3, isBoss: false))
        }
        persist()
    }

    /// Testing-only: replaces the inventory with exact items, so item
    /// fusion tests can set up deterministic "same kind" duplicates without
    /// relying on `EquipmentFactory`'s randomness.
    func debugSetInventory(_ items: [EquipmentItem]) {
        save.inventory = items
        persist()
    }

    /// Test-only: replaces the roster wholesale so fusion/duplicate logic
    /// can be exercised against an exact, hand-built set of instances
    /// instead of grinding real summons first.
    func debugSetRoster(_ instances: [DreamkeeperInstance]) {
        save.roster = instances
        persist()
    }

    /// QA-only: adds `count` extra duplicate instances of the first roster
    /// member's species, so the fusion picker can be exercised without
    /// grinding duplicate summons first. Only invoked when `DK_SEED_SHARDS`
    /// is set.
    func debugSeedDuplicates(_ count: Int = 20) {
        guard let first = save.roster.first else { return }
        for _ in 0..<count {
            save.roster.append(DreamkeeperInstance(definitionID: first.definitionID))
        }
        persist()
    }

    /// QA-only: adds `count` identical duplicate items to the inventory so
    /// the item fusion picker can be exercised without grinding for matching
    /// drops first. Only invoked when `DK_SEED_ITEM_DUPLICATES` is set.
    func debugSeedItemDuplicates(_ count: Int = 5) {
        let template = EquipmentFactory.randomItem(forStage: 3, isBoss: false)
        for _ in 0..<count {
            save.inventory.append(EquipmentItem(
                slot: template.slot, name: template.name, rarity: template.rarity,
                level: 1, statBonus: template.statBonus
            ))
        }
        persist()
    }

    /// QA-only: jumps the campaign frontier straight to `stage` (and selects
    /// it) so a specific encounter — e.g. a boss stage — can be reached
    /// without clearing everything before it. Only invoked when
    /// `DK_SEED_STAGE` is set to a stage number.
    func debugSeedStage(_ stage: Int) {
        save.currentStage = stage
        selectedStage = stage
        persist()
    }

    /// QA-only: discovers a handful of monsters/bosses across every world so
    /// the Dream Observatory's unlocked-entry state can be exercised without
    /// grinding through battles first. Only invoked when `DK_SEED_BESTIARY`
    /// is set.
    func debugSeedBestiary() {
        for world in WorldCatalog.worlds {
            let entries = MonsterCatalog.allEntries(forWorld: world.id)
            for entry in entries.prefix(2) {
                save.discoveredMonsters.insert(entry.name)
            }
        }
        persist()
    }

    /// QA-only: grants enough Battle Pass XP to reach tier 3 and unlocks
    /// Premium, so both claimable and premium-locked reward states can be
    /// exercised without grinding battles first. Only invoked when
    /// `DK_SEED_BATTLEPASS` is set.
    func debugSeedBattlePass() {
        save.battlePassXP = BattlePassSystem.xpPerTier * 3
        save.battlePassPremiumUnlocked = true
        persist()
    }

    /// QA-only: backdates both offline-building timers so the Gold Fountain
    /// and Training Garden show pending rewards without waiting for real
    /// time to pass. Only invoked when `DK_SEED_OFFLINE` is set.
    func debugSeedOfflineTime() {
        let backdated = Date().addingTimeInterval(-45 * 60)
        save.lastGoldCollectedAt = backdated
        save.lastTrainingCollectedAt = backdated
        persist()
    }

    /// QA-only: marks every daily and weekly mission as complete (unclaimed)
    /// so the Claim state can be screenshotted without playing through each
    /// one. Only invoked when `DK_SEED_MISSIONS` is set.
    func debugCompleteAllMissions() {
        ensureMissionsCurrent()
        for def in DailyMissions.definitions {
            save.dailyMissionProgress[def.id.rawValue] = def.target
        }
        ensureWeeklyMissionsCurrent()
        for def in WeeklyMissions.definitions {
            save.weeklyMissionProgress[def.id.rawValue] = def.target
        }
        persist()
    }
}
