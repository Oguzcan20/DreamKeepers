import SwiftUI

struct DreamHavenView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var showGoldFountain = false
    @State private var showTrainingGarden = false
    @State private var showMissions = false
    @State private var showLoginReward = false
    @State private var showRewardedAd = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                // Fixed layout, no `ScrollView` — Dream Haven is the hub
                // screen the player lands on constantly, so it needs to read
                // at a glance in landscape without a scroll hint. Only the
                // genuinely list-shaped screens (Campaign, Inventory, …)
                // keep scrolling; this one is sized to always fit instead.
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 10) {
                        teamSnapshotCard
                        battlePassBanner
                    }
                    .frame(width: 280)

                    buildingsGrid
                        .frame(maxWidth: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .frame(maxHeight: .infinity)
                .opacity(appeared ? 1 : 0)

                footer
                    .opacity(appeared ? 1 : 0)
            }
            // No `ScrollView` on this screen (see comment above), so a
            // smaller phone's shorter landscape height has no scroll
            // fallback if the fixed cards don't fit — scale the whole
            // layout down uniformly instead of letting it clip.
            .adaptiveScale()
        }
        .onAppear {
            switch ProcessInfo.processInfo.environment["DK_OPEN_BUILDING"] {
            case "gold": showGoldFountain = true
            case "training": showTrainingGarden = true
            case "missions": showMissions = true
            default: break
            }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .sheet(isPresented: $showGoldFountain) {
            GoldFountainSheet(gameState: gameState)
                .presentationDetents([.height(230), .medium])
        }
        .sheet(isPresented: $showTrainingGarden) {
            TrainingGardenSheet(gameState: gameState)
                .presentationDetents([.height(230), .medium])
        }
        .sheet(isPresented: $showMissions) {
            MissionsSheet(gameState: gameState)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showLoginReward) {
            LoginRewardSheet(gameState: gameState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRewardedAd) {
            RewardedAdSheet(gameState: gameState)
                .presentationDetents([.medium])
                .interactiveDismissDisabled()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dream Haven")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Button {
                    navigate(.profile)
                } label: {
                    Text("Player Lv \(gameState.save.playerLevel)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            settingsButton
            shopButton
            missionsButton
            loginRewardButton
            resourceBar
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Theme.deepNavy.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, .white.opacity(0.14), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    private var settingsButton: some View {
        Button {
            navigate(.settings)
        } label: {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .accessibilityLabel("Settings")
    }

    private var shopButton: some View {
        Button {
            navigate(.shop)
        } label: {
            Image(systemName: "cart.fill")
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
        }
        .accessibilityLabel("Shop")
    }

    private var missionsButton: some View {
        Button {
            showMissions = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                if gameState.hasUnclaimedMissions {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel("Daily Missions")
    }

    private var loginRewardButton: some View {
        Button {
            showLoginReward = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                if gameState.isLoginRewardAvailable {
                    Circle()
                        .fill(Theme.gold)
                        .frame(width: 10, height: 10)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel("Daily Login Bonus")
    }

    /// Gold/Gems/Energy as one merged capsule instead of three stacked
    /// `ResourcePill`s — three separate pills piled vertically read as a
    /// cramped little tower next to the header buttons; one wide bar with
    /// hairline dividers between the values reads as a single deliberate
    /// readout, same visual family as `ResourcePill` (same material/stroke)
    /// so it still matches Shop/Battle Pass's standalone pills elsewhere.
    private var resourceBar: some View {
        HStack(spacing: 0) {
            resourceItem(systemImage: "circle.hexagongrid.fill", value: "\(gameState.save.gold)", tint: Theme.gold, label: "Gold")
            resourceDivider
            resourceItem(systemImage: "sparkles", value: "\(gameState.save.dreamGems)", tint: Theme.violet, label: "Dream Gems")
            resourceDivider
            resourceItem(systemImage: "bolt.fill", value: "\(gameState.energy)/\(gameState.maxEnergy)", tint: Theme.softBlue, label: "Energy")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        )
    }

    private func resourceItem(systemImage: String, value: String, tint: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    private var resourceDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.14))
            .frame(width: 1, height: 15)
    }

    // MARK: - Team Snapshot

    /// Replaces the old static hero banner image (removed entirely — it had
    /// no function beyond decoration). This card earns its space instead:
    /// it shows the player's actual deployed team at a glance and jumps
    /// straight to Inventory to change it, so the top of Dream Haven now
    /// reflects live game state instead of a fixed picture.
    private var teamSnapshotCard: some View {
        Button {
            navigate(.team)
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Your Team", systemImage: "shield.lefthalf.filled")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.35))
                    }

                    if gameState.deployedTeam.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "person.fill.badge.plus")
                                .font(.title3)
                                .foregroundStyle(Theme.softBlue)
                            Text("No Dreamkeepers deployed yet. Tap to build your team.")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        HStack(spacing: 10) {
                            ForEach(gameState.deployedTeam.prefix(5)) { instance in
                                if let def = gameState.definition(for: instance) {
                                    TeamAvatar(definition: def)
                                }
                            }
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                            Text("Team Power \(teamPower)")
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    /// Rough at-a-glance strength score (not a battle-accurate formula) for
    /// the deployed team — purely a satisfying number to watch grow.
    private var teamPower: Int {
        gameState.deployedTeam.reduce(0) { total, instance in
            let stats = gameState.currentStats(for: instance)
            return total + Int(stats.hp / 10 + stats.attack + stats.defense + stats.speed)
        }
    }

    private var battlePassBanner: some View {
        // A real `Button` (not `.onTapGesture`) so VoiceOver announces this
        // as an actionable control — same fix already applied to the Summon
        // screen's chest and to `teamSnapshotCard` below. `.plain` keeps the
        // card's own look; the accessibility modifiers collapse the whole
        // card into one spoken element with a proper label instead of
        // reading each child text/icon separately.
        Button {
            navigate(.battlePass)
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Theme.gold.opacity(0.18))
                        .frame(width: 40, height: 40)
                        .blur(radius: 6)
                    Image(systemName: "rosette")
                        .font(.title2)
                        .foregroundStyle(Theme.gold)
                        .frame(width: 30)
                    if gameState.hasUnclaimedBattlePassRewards {
                        Circle().fill(Theme.gold).frame(width: 8, height: 8).offset(x: 6, y: -2)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Season Pass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Tier \(gameState.battlePassTier)/\(BattlePassSystem.tierCount)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                    GeometryReader { geo in
                        let progress = gameState.battlePassProgress
                        let fraction = progress.needed > 0 ? CGFloat(progress.current) / CGFloat(progress.needed) : 0
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.gold.opacity(0.7), Theme.gold],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * (appeared ? fraction : 0))
                                .animation(.easeOut(duration: 0.7).delay(0.15), value: appeared)
                        }
                    }
                    .frame(height: 6)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Season Pass, Tier \(gameState.battlePassTier) of \(BattlePassSystem.tierCount)")
    }

    private var buildingsGrid: some View {
        // No section heading here — the screen's own title (`header`, right
        // above this) already says "Dream Haven"; repeating it as a second,
        // identical label read as a copy/paste duplicate rather than a
        // distinct section.
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                BuildingCard(
                    icon: "sparkles", name: "Summoning Shrine",
                    status: "\(gameState.save.dreamGems) Gems", isActive: true, isReady: false, delay: 0,
                    accent: Theme.violet
                ) {
                    navigate(.summon)
                }
                BuildingCard(
                    icon: "leaf.arrow.circlepath", name: "Training Garden",
                    status: gameState.pendingTrainingGardenReward > 0 ? "+\(gameState.pendingTrainingGardenReward) EXP ready" : "Tap to collect",
                    isActive: true, isReady: gameState.pendingTrainingGardenReward > 0, delay: 0.05
                ) {
                    showTrainingGarden = true
                }
                BuildingCard(
                    icon: "circle.hexagongrid.fill", name: "Gold Fountain",
                    status: gameState.pendingGoldFountainReward > 0 ? "+\(gameState.pendingGoldFountainReward) Gold ready" : "Tap to collect",
                    isActive: true, isReady: gameState.pendingGoldFountainReward > 0, delay: 0.1
                ) {
                    showGoldFountain = true
                }
                BuildingCard(
                    icon: "sparkle.magnifyingglass", name: "Dream Observatory",
                    status: "\(gameState.bestiaryDiscoveredCount)/\(gameState.bestiaryTotalCount) Discovered",
                    isActive: true, isReady: false, delay: 0.15
                ) {
                    navigate(.observatory)
                }
                BuildingCard(
                    icon: gameState.arenaTier.symbol, name: "The Endless Trial",
                    status: "Floor \(gameState.arenaFloor)/\(gameState.arenaMaxFloor)",
                    isActive: true, isReady: false, delay: 0.18,
                    accent: Theme.gold
                ) {
                    navigate(.arena)
                }
                if gameState.isRewardedAdAvailable {
                    BuildingCard(
                        icon: "play.rectangle.fill", name: "Watch Ad",
                        status: "+\(GameState.rewardedAdGold) Gold, +\(GameState.rewardedAdGems) Gems · \(gameState.rewardedAdWatchesRemainingToday)/\(GameState.maxRewardedAdsPerDay) today",
                        isActive: true, isReady: true, delay: 0.2
                    ) {
                        showRewardedAd = true
                    }
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    navigate(.team)
                } label: {
                    Label("Inventory", systemImage: "person.3.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.softBlue))

                Button {
                    navigate(.campaign)
                } label: {
                    Label("Campaign", systemImage: "map.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                .disabled(gameState.deployedTeam.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [.clear, Theme.deepNavy.opacity(0.6), Theme.deepNavy], startPoint: .top, endPoint: .bottom)
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [.clear, .white.opacity(0.14), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
    }
}

/// Small circular portrait used in `teamSnapshotCard` — real art when
/// available, otherwise the same rarity-gradient + symbol fallback used
/// across the app (Codex, Inventory), so a fresh roster with no imported art
/// still reads correctly.
private struct TeamAvatar: View {
    let definition: DreamkeeperDefinition

    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }

    var body: some View {
        ZStack {
            if hasArt {
                Image(DreamkeeperArt.assetName(for: definition.name))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 38)
                    .clipShape(Circle())
            } else {
                Circle().fill(definition.rarity.gradient).frame(width: 38, height: 38)
                Image(systemName: definition.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .overlay(
            Circle().strokeBorder(definition.rarity.gradient, lineWidth: 1.5)
                .frame(width: 38, height: 38)
        )
        .shadow(color: definition.rarity.glows ? definition.rarity.primaryColor.opacity(0.5) : .clear, radius: 5)
    }
}

private struct BuildingCard: View {
    var icon: String
    var name: String
    // LocalizedStringKey, not String: call sites pass interpolated literals
    // directly ("+\(n) Gold ready"), which only compiles to a %lld-keyed
    // catalog lookup when the parameter itself is LocalizedStringKey — a
    // String parameter would receive the number already baked into plain
    // text, and no catalog key ever matches a moving number.
    var status: LocalizedStringKey
    var isActive: Bool
    /// Whether a reward is waiting to be collected — draws a gentle glow
    /// pulse so ready buildings visibly stand out from the rest of the grid
    /// instead of relying purely on the caption text color.
    var isReady: Bool
    var delay: Double
    /// Optional per-building identity color — set this to make one building
    /// (currently just the Summoning Shrine) read as its own distinctive
    /// place on the grid instead of sharing the generic gold/white treatment
    /// every other tile uses, the same accented-card language established
    /// for the Shop's starter/VIP cards and Campaign's world cards.
    var accent: Color? = nil
    var onTap: (() -> Void)?

    @State private var appeared = false
    @State private var pulse = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                if isReady {
                    Circle()
                        .fill(Theme.gold.opacity(0.35))
                        .frame(width: 30, height: 30)
                        .blur(radius: 7)
                        .scaleEffect(pulse ? 1.25 : 0.9)
                        .opacity(pulse ? 0.9 : 0.4)
                } else if let accent {
                    Circle()
                        .fill(accent.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .blur(radius: 7)
                }
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(accent ?? (isActive ? Theme.gold : .white.opacity(0.4)))
            }
            .frame(height: 18)

            Text(LocalizedStringKey(name))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(3)
                // German compound names ("Beschwörungsschrein") are single
                // unbreakable words wider than the card at full size — with
                // no space to wrap on, SwiftUI hard-hyphenates instead. A
                // more aggressive scale factor lets the word shrink to fit
                // on one line before that kicks in.
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
            Text(status)
                .font(.caption2)
                .foregroundStyle(isReady ? Theme.gold : (isActive ? Theme.softBlue : .white.opacity(0.4)))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(Theme.cardBackground)
        .background(
            LinearGradient(colors: [.white.opacity(0.07), .clear], startPoint: .top, endPoint: .bottom)
        )
        .background(
            // Faint accent wash behind the whole tile, not just the icon
            // glow — same radial-tint trick as `WorldSection`/`GemPackCard`,
            // toned down to fit a much smaller card.
            accent.map { color in
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RadialGradient(colors: [color.opacity(0.16), .clear], center: .topLeading, startRadius: 2, endRadius: 90))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isReady ? Theme.gold.opacity(0.5) : (accent?.opacity(0.45) ?? Theme.cardStroke), lineWidth: isReady || accent != nil ? 1.25 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: isReady ? Theme.gold.opacity(0.25) : (accent?.opacity(0.2) ?? .clear), radius: 8, y: 3)
        .opacity(isActive ? 1 : 0.6)
        .scaleEffect(appeared ? 1 : 0.9)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75).delay(delay)) {
                appeared = true
            }
            if isReady {
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if isActive { onTap?() } }
        // `.onTapGesture` alone gives VoiceOver nothing — no `.isButton`
        // trait, no combined label, so every tile in the hub's main grid
        // was silently untappable for a screen reader user. `Button` isn't
        // usable here without a bigger restyle (it would fight the tile's
        // own press/appear animations), so add the traits and a spoken
        // label by hand instead — same gap, same fix as the Summon screen's
        // chest and `battlePassBanner` above.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LocalizedStringKey(name))
        .accessibilityValue(status)
        .accessibilityAddTraits(isActive ? .isButton : [])
    }
}
