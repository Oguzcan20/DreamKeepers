import SwiftUI

enum AppRoute: Equatable {
    case mainMenu
    case dreamHaven
    case team
    case campaign
    case summon
    case shop
    case settings
    case profile
    case observatory
    case battlePass
    case codex
    case battle
    case result(BattleResultSummary)
    case arena
    case arenaBattle
    case arenaResult(ArenaBattleResultSummary)
    case dungeon
    case dungeonBattle(DungeonID)
    case dungeonResult(DungeonBattleResultSummary)
    case friends
}

struct RootView: View {
    @State private var gameState: GameState
    @State private var accountState = AccountState()
    @State private var gameCenterService = GameCenterService()
    @State private var leaderboardService = LeaderboardService()
    @State private var friendsService = FriendsService()
    @State private var route: AppRoute
    @State private var activeEngine: BattleEngine?
    @State private var activeArenaEngine: BattleEngine?
    @State private var activeDungeonEngine: BattleEngine?
    @State private var activeDungeon: DungeonID?
    @State private var isLoading: Bool
    @State private var activeAchievementPopup: Achievement?
    @State private var showLoginReward = false
    @State private var showInterstitial = false
    /// Guards the auto-popup to once per app launch — dismissing it without
    /// claiming should never spam it again on every Dream Haven visit; the
    /// gift button in `DreamHavenView`'s header stays available regardless.
    @State private var hasOfferedLoginRewardThisLaunch = false
    /// Guards the ATT prompt to once per app launch — `TrackingPermission`
    /// itself no-ops once the user has answered, but this also stops a
    /// second `onAppear` (e.g. after backgrounding/foregrounding) from
    /// re-firing the delay timer for no reason.
    @State private var hasRequestedTrackingThisLaunch = false

    /// `DK_START_ROUTE` (dreamHaven/team/battle) lets QA/screenshot tooling
    /// jump straight to a screen without scripting taps. No effect unless set.
    /// It also skips the splash/loading screen so tooling isn't slowed down
    /// by an animation with nothing to actually verify.
    init() {
        let state = GameState()
        if ProcessInfo.processInfo.environment["DK_SEED_ITEM"] != nil {
            state.debugSeedInventory()
        }
        if ProcessInfo.processInfo.environment["DK_SEED_OFFLINE"] != nil {
            state.debugSeedOfflineTime()
        }
        if ProcessInfo.processInfo.environment["DK_SEED_MISSIONS"] != nil {
            state.debugCompleteAllMissions()
        }
        if let stageString = ProcessInfo.processInfo.environment["DK_SEED_STAGE"], let stage = Int(stageString) {
            state.debugSeedStage(stage)
        }
        if ProcessInfo.processInfo.environment["DK_SEED_BESTIARY"] != nil {
            state.debugSeedBestiary()
        }
        if ProcessInfo.processInfo.environment["DK_SEED_BATTLEPASS"] != nil {
            state.debugSeedBattlePass()
        }
        if ProcessInfo.processInfo.environment["DK_SEED_SHARDS"] != nil {
            state.debugSeedDuplicates()
        }
        if ProcessInfo.processInfo.environment["DK_SEED_ITEM_DUPLICATES"] != nil {
            state.debugSeedItemDuplicates()
        }
        if let language = ProcessInfo.processInfo.environment["DK_LANGUAGE"] {
            state.setPreferredLanguage(language)
        }
        _gameState = State(initialValue: state)
        let startRoute = ProcessInfo.processInfo.environment["DK_START_ROUTE"]
        _isLoading = State(initialValue: startRoute == nil)
        switch startRoute {
        case "mainMenu": _route = State(initialValue: .mainMenu)
        case "dreamHaven": _route = State(initialValue: .dreamHaven)
        case "team": _route = State(initialValue: .team)
        case "campaign": _route = State(initialValue: .campaign)
        case "summon": _route = State(initialValue: .summon)
        case "shop": _route = State(initialValue: .shop)
        case "settings": _route = State(initialValue: .settings)
        case "profile": _route = State(initialValue: .profile)
        case "friends": _route = State(initialValue: .friends)
        case "observatory": _route = State(initialValue: .observatory)
        case "battlePass": _route = State(initialValue: .battlePass)
        case "codex": _route = State(initialValue: .codex)
        case "battle": _route = State(initialValue: .battle)
        case "arena": _route = State(initialValue: .arena)
        case "dungeon": _route = State(initialValue: .dungeon)
        default: _route = State(initialValue: .mainMenu)
        }
    }

    /// Every screen has its own way back, but a couple of them have shown a
    /// recurring, never fully pinned-down SwiftUI layout bug where an
    /// unrelated state change on the screen quietly breaks that screen's own
    /// back button, with no consistent trigger to test against. This
    /// app-level button lives in `RootView`'s own body instead of any
    /// individual screen — the one part of the app that has never been
    /// affected by that bug all session — so there is always at least one
    /// guaranteed, obvious way home no matter what a screen's own layout is
    /// doing.
    ///
    /// The Summoning Shrine and Dreamkeeper Codex are excluded here — turns
    /// out this button's own bottom `safeAreaInset` reservation (165pt,
    /// sized to sit clear of a scrollable card grid) was the actual root
    /// cause of those screens' header-disappearing bug: both
    /// `SummoningShrineView` and `DreamkeeperCodexView`/
    /// `DreamkeeperCodexDetailView` force-fit themselves to the true
    /// full-screen size (`UIScreen.main.bounds.size`, their own workaround
    /// for a *different* height-overflow bug) rather than the reduced size
    /// this inset proposes, so the composite view overflows this ZStack and
    /// gets clipped symmetrically top-and-bottom, taking the header (and, on
    /// the Codex detail page, its only close button) with it — confirmed by
    /// reproducing the bug on-device. Both already have their own back/close
    /// button and their own drag-down-to-dismiss gesture, so they never
    /// needed this redundant floating one anyway.
    private var showsGlobalHomeButton: Bool {
        switch route {
        case .mainMenu, .battle, .result, .dreamHaven, .summon, .arenaBattle, .arenaResult, .codex,
             .dungeonBattle, .dungeonResult:
            return false
        default: return true
        }
    }

    /// How much bottom clearance `currentScreen` reserves for the floating
    /// home button (see the `.safeAreaInset` below). 165pt was tuned for
    /// *scrollable* screens (Shop, Inventory, Campaign) where the last card
    /// can end up right behind the button. `.profile` uses the fixed,
    /// non-scrolling `AdaptiveScale` layout instead — reserving the same
    /// 165pt there ate over a third of the whole landscape height before
    /// `AdaptiveScale` ever got to measure it, forcing its two cards much
    /// smaller than necessary. A much smaller clearance is enough since the
    /// button only lives in the bottom-left corner.
    private var homeButtonClearance: CGFloat {
        route == .profile ? 56 : 165
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if isLoading {
                LoadingView {
                    withAnimation(.easeOut(duration: 0.35)) { isLoading = false }
                }
                .transition(.opacity)
            } else {
                currentScreen
                    // Reserves room at the bottom so the floating home
                    // button below never sits on top of a screen's own
                    // scrollable content (it used to cover the last visible
                    // card on Inventory/Campaign/Shop) — a plain
                    // `ScrollView` respects a safe-area inset by pushing its
                    // content up, so this doesn't touch any individual
                    // screen's own layout.
                    .safeAreaInset(edge: .bottom) {
                        if showsGlobalHomeButton {
                            // 60 still let the pill's rounded background
                            // graze the last card's corner on Shop (its two
                            // columns can run taller than one screen); a
                            // few extra points of clearance fixes that
                            // without visibly changing anything else.
                            Color.clear.frame(height: homeButtonClearance)
                        }
                    }
                    .transition(.opacity)
            }

            overlays
        }
        .animation(.easeOut(duration: 0.22), value: route)
        .onChange(of: route) { _, newRoute in
            if newRoute == .battle {
                activeEngine = gameState.makeBattleEngine()
            }
        }
        .onChange(of: gameState.currentStage) { _, newStage in
            leaderboardService.submitCampaignProgress(stage: newStage)
            friendsService.updateMyProgress(playerLevel: gameState.save.playerLevel, currentStage: newStage)
        }
        .onChange(of: gameState.save.playerLevel) { _, newLevel in
            friendsService.updateMyProgress(playerLevel: newLevel, currentStage: gameState.currentStage)
        }
        .onChange(of: gameCenterService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                leaderboardService.submitCampaignProgress(stage: gameState.currentStage)
            }
        }
        .onChange(of: gameState.pendingAchievements) { _, newValue in
            if activeAchievementPopup == nil, !newValue.isEmpty {
                showNextAchievementPopup()
            }
        }
        .onChange(of: route) { _, newRoute in
            if newRoute == .dreamHaven {
                maybeOfferLoginReward()
            }
        }
        .sheet(isPresented: $showLoginReward) {
            LoginRewardSheet(gameState: gameState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showInterstitial) {
            InterstitialAdSheet(gameState: gameState)
                .interactiveDismissDisabled()
        }
        .onChange(of: showInterstitial) { _, isShowing in
            // The login-reward offer defers to a showing interstitial (see
            // `maybeOfferLoginReward`) — re-check the instant it's gone so
            // the offer isn't lost for the rest of the launch.
            if !isShowing { maybeOfferLoginReward() }
        }
        .onAppear {
            if route == .battle, activeEngine == nil {
                activeEngine = gameState.makeBattleEngine()
            }
            if activeAchievementPopup == nil {
                showNextAchievementPopup()
            }
            maybeOfferLoginReward()
            gameCenterService.presentingViewController = { UIApplication.dk_rootViewController }
            // Game Center's own "Signed In As ..." toast is system-drawn and
            // always lands near the top of the screen — right on top of the
            // Main Menu's logo if triggered while it's showing. Authenticating
            // only once the player has actually left the Main Menu keeps that
            // toast off the one screen it would visibly clash with; it still
            // fires on the very first navigation, so nothing is delayed for
            // long.
            if route != .mainMenu {
                gameCenterService.authenticate()
            }
            friendsService.start(playerLevel: gameState.save.playerLevel, currentStage: gameState.currentStage)
            if !hasRequestedTrackingThisLaunch {
                hasRequestedTrackingThisLaunch = true
                // A beat after the app is actually visible — firing this at
                // the literal first frame (still mid-transition into the
                // foreground) makes iOS silently skip the prompt instead of
                // showing it.
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    // GDPR/EEA consent must be resolved before ATT is
                    // requested and before any ad loads, per Google's own
                    // integration guide — see ConsentManager's doc comment.
                    await ConsentManager.requestConsentIfNeeded()
                    await TrackingPermission.requestIfNeeded()
                }
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, gameState.preferredLocale)
    }

    /// Every full-screen/overlay layer stacked on top of `currentScreen` —
    /// split out of `body` because the compiler's expression-type-checker
    /// times out on a single `ZStack` builder carrying this many stacked
    /// conditionals (each with its own `.transition`/`.zIndex`). Splitting
    /// it into its own `@ViewBuilder` gives the compiler a much smaller
    /// expression to solve at each level; behavior is unchanged.
    @ViewBuilder
    private var overlays: some View {
        // Shown once, the first time a new save actually reaches Dream
        // Haven — not on the Main Menu, so it doesn't compete with the
        // Play button, and not before, since `newGame()` already deploys
        // a starter Dreamkeeper without any tutorial needed to get there.
        if route == .dreamHaven, !gameState.hasSeenOnboarding {
            OnboardingView {
                gameState.completeOnboarding()
            }
            .transition(.opacity)
            .zIndex(2)
        }

        // Right after onboarding finishes — locks in the starter Olf's
        // element (or, via the secret hold-on-Ember gesture, Ultimate
        // Olf). `needsStarterOlfChoice` is naturally false for saves
        // from before this feature existed, so it never appears for them.
        if route == .dreamHaven, gameState.hasSeenOnboarding, gameState.needsStarterOlfChoice {
            StarterOlfChoiceView { element in
                gameState.chooseStarterOlf(element: element)
            }
            .transition(.opacity)
            .zIndex(2)
        }

        // A toast, not a takeover — achievements fire mid-play from any
        // screen (a fusion, a summon, a battle win), so this has to
        // announce itself without blocking whatever the player is doing.
        if let activeAchievementPopup {
            VStack {
                AchievementToast(achievement: activeAchievementPopup) {
                    dismissAchievementPopup()
                }
                Spacer()
            }
            .padding(.top, 10)
            .transition(.move(edge: .top).combined(with: .opacity))
            .zIndex(3)
        }

        if showsGlobalHomeButton {
            VStack {
                Spacer()
                HStack {
                    Button {
                        route = .dreamHaven
                    } label: {
                        Label("Dream Haven", systemImage: "house.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(.ultraThinMaterial)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.bottom, 14)
            }
            .allowsHitTesting(true)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch route {
        case .mainMenu:
            MainMenuView(gameState: gameState) {
                navigate(to: .dreamHaven)
            } onSettings: {
                navigate(to: .settings)
            }
        case .settings:
            SettingsView(gameState: gameState, accountState: accountState, gameCenterService: gameCenterService) { destination in
                navigate(to: destination)
            }
        case .profile:
            ProfileView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .friends:
            FriendsView(friendsService: friendsService) { destination in
                navigate(to: destination)
            }
        case .observatory:
            BestiaryView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .battlePass:
            BattlePassView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .codex:
            DreamkeeperCodexView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .dreamHaven:
            DreamHavenView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .team:
            InventoryView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .campaign:
            CampaignView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .summon:
            SummoningShrineView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .shop:
            ShopView(gameState: gameState) { destination in
                navigate(to: destination)
            }
        case .battle:
            if let engine = activeEngine {
                BattleView(engine: engine, gameState: gameState) { finishedEngine in
                    let summary = gameState.applyBattleResult(from: finishedEngine)
                    navigate(to: .result(summary))
                }
            }
        case .result(let summary):
            BattleResultView(
                summary: summary, gameState: gameState,
                onContinue: {
                    activeEngine = nil
                    navigate(to: .dreamHaven)
                    maybeShowInterstitial()
                },
                onNextBattle: (summary.outcome == .victory && !gameState.isCampaignComplete) ? {
                    // `selectedStage` already advanced past the just-cleared
                    // stage inside `applyBattleResult`, so re-entering
                    // `.battle` builds a fresh engine for the next fight —
                    // same path `CampaignView` uses, just skipping the trip
                    // through Dream Haven in between.
                    activeEngine = nil
                    navigate(to: .battle)
                    maybeShowInterstitial()
                } : nil
            )
        case .arena:
            ArenaView(gameState: gameState) { destination in
                navigate(to: destination)
            } onFight: { floor in
                guard let engine = gameState.makeArenaBattleEngine(floor: floor) else { return }
                activeArenaEngine = engine
                navigate(to: .arenaBattle)
            }
        case .arenaBattle:
            if let engine = activeArenaEngine {
                BattleView(engine: engine, gameState: gameState, arenaFloor: engine.stage) { finishedEngine in
                    let summary = gameState.applyArenaBattleResult(from: finishedEngine)
                    navigate(to: .arenaResult(summary))
                }
            }
        case .arenaResult(let summary):
            ArenaResultView(summary: summary) {
                activeArenaEngine = nil
                navigate(to: .arena)
            } onDreamHaven: {
                activeArenaEngine = nil
                navigate(to: .dreamHaven)
            }
        case .dungeon:
            DungeonView(gameState: gameState) { destination in
                navigate(to: destination)
            } onFight: { dungeon in
                guard let engine = gameState.makeDungeonBattleEngine(dungeon) else { return }
                activeDungeonEngine = engine
                activeDungeon = dungeon
                navigate(to: .dungeonBattle(dungeon))
            }
        case .dungeonBattle(let dungeon):
            if let engine = activeDungeonEngine {
                BattleView(engine: engine, gameState: gameState, dungeonName: DungeonSystem.displayName(dungeon)) { finishedEngine in
                    let summary = gameState.applyDungeonBattleResult(from: finishedEngine, dungeon: dungeon)
                    navigate(to: .dungeonResult(summary))
                }
            }
        case .dungeonResult(let summary):
            DungeonResultView(summary: summary) {
                activeDungeonEngine = nil
                activeDungeon = nil
                navigate(to: .dungeon)
            } onDreamHaven: {
                activeDungeonEngine = nil
                activeDungeon = nil
                navigate(to: .dreamHaven)
            }
        }
    }

    private func navigate(to destination: AppRoute) {
        if route == .mainMenu, !gameCenterService.isAuthenticated {
            gameCenterService.authenticate()
        }
        route = destination
    }

    // MARK: - Interstitial ads

    /// Checked right after a battle-result screen is dismissed — see
    /// `GameState.shouldShowInterstitial`.
    private func maybeShowInterstitial() {
        guard gameState.shouldShowInterstitial else { return }
        showInterstitial = true
    }

    // MARK: - Login reward

    /// Auto-presents the login-streak calendar the first time Dream Haven
    /// is reached this launch, once onboarding is out of the way and a
    /// reward is actually still unclaimed for today.
    private func maybeOfferLoginReward() {
        // An interstitial can trigger on the very same transition (a stage
        // win landing back on Dream Haven) — bail without consuming
        // `hasOfferedLoginRewardThisLaunch` so `showInterstitial`'s own
        // dismissal re-checks this instead of losing the offer for the rest
        // of the launch.
        guard route == .dreamHaven, gameState.hasSeenOnboarding, gameState.isLoginRewardAvailable,
              !hasOfferedLoginRewardThisLaunch, !showLoginReward, !showInterstitial else { return }
        hasOfferedLoginRewardThisLaunch = true
        // Let the Dream Haven transition settle instead of popping the
        // instant the screen appears.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showLoginReward = true
        }
    }

    // MARK: - Achievement popups

    private func showNextAchievementPopup() {
        guard let next = gameState.consumeNextPendingAchievement() else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { activeAchievementPopup = next }
    }

    /// Guarded against a double-fire (tap-to-dismiss racing the toast's own
    /// auto-dismiss timer): once `activeAchievementPopup` is nil, a second
    /// call is a no-op instead of skipping ahead an extra queued toast.
    private func dismissAchievementPopup() {
        guard activeAchievementPopup != nil else { return }
        withAnimation(.easeIn(duration: 0.2)) { activeAchievementPopup = nil }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showNextAchievementPopup()
        }
    }
}

/// A gold-ringed toast banner for a newly-unlocked `Achievement` — slides
/// in from the top over whatever screen is currently showing (achievements
/// can complete mid-play, from a battle win, fusion, or summon) rather than
/// blocking play with a full takeover. Auto-dismisses after a few seconds,
/// or tap to dismiss early.
private struct AchievementToast: View {
    let achievement: Achievement
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.3)).frame(width: 50, height: 50)
                Image(systemName: achievement.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.gold)
            }
            .shadow(color: Theme.gold.opacity(0.7), radius: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.gold)
                Text(LocalizedStringKey(achievement.title))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(achievement.detail))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.gold.opacity(0.35), radius: 16, y: 6)
        .frame(maxWidth: 360)
        .padding(.horizontal, 20)
        .scaleEffect(appeared ? 1 : 0.9)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture { dismiss() }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeIn(duration: 0.25)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onDismiss()
        }
    }
}

#Preview {
    RootView()
}
