import SwiftUI

/// Which currency this screen is currently pulling — Dreamkeepers (the
/// original flow, full tap-escalation ladder and showcase) or Equipment (a
/// deliberately simpler parallel flow, see the state block below).
enum SummonKind: String, CaseIterable, Identifiable {
    case dreamkeeper = "Dreamkeepers"
    case equipment = "Equipment"
    var id: String { rawValue }
}

/// Summoning Shrine (German: "Beschwörung"). The pull itself is
/// resolved instantly server-side-equivalent (`GameState.performSummon`),
/// but the reveal is staged as a tappable treasure chest: each tap escalates
/// a glow hint through the rarity ladder (uncommon → rare → epic →
/// legendary) until it reaches the actual result and bursts open — so the
/// player gets a sense of "how good is this" building up before seeing the
/// name, without the outcome ever being anything but already decided.
struct SummoningShrineView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    /// Dreamkeepers vs Equipment — switches which of the two parallel pull
    /// flows below is on screen. Defaults to Dreamkeepers so nothing about
    /// the existing, already-tuned flow changes for a player who never
    /// touches the new picker.
    @State private var summonKind: SummonKind = .dreamkeeper

    /// The last fully-revealed pull, shown in the side panel.
    @State private var lastResult: SummonResult?

    /// The in-flight pull: gems already spent and rarity already rolled,
    /// waiting on the player to tap the chest open (or skip straight there).
    @State private var revealResult: SummonResult?
    @State private var tapsSoFar = 0
    @State private var chestOpened = false
    @State private var wiggle = false
    /// Drives the closed chest's idle bob + glow pulse between pulls — set
    /// once on appear and left running continuously; only actually visible
    /// while `revealResult == nil`, so it never fights the tap/burst
    /// animations that take over once a pull is in flight.
    @State private var idlePulse = false
    @State private var legendaryShimmerSpin = false
    @State private var legendaryFlash = false
    @State private var shakeOffsetX: CGFloat = 0

    /// A full-screen color wash timed to the exact instant the chest pops
    /// open — every rarity gets one now (not just Legendary/Mythic), scaled
    /// up in opacity/duration as the rarity climbs, so even a Common pull
    /// reads as "something happened" instead of the chest silently
    /// swapping textures.
    @State private var screenFlashOpacity: Double = 0

    /// An expanding, fading ring burst centered on the chest the instant it
    /// opens — cheap (one stroked `Circle`, no gradient — this screen has a
    /// confirmed history of gradients corrupting its compositing) but reads
    /// as a genuine shockwave.
    @State private var impactRingScale: CGFloat = 0.5
    @State private var impactRingOpacity: Double = 0

    /// The "10+1 free" bulk pull skips the chest-tap suspense entirely —
    /// with 11 results at once, a per-pull reveal sequence would just be
    /// tedious, so it opens straight into a staggered reveal grid instead.
    @State private var multiResults: [SummonResult] = []
    @State private var showMultiResults = false
    /// Regenerated on every `multiSummon()` call and applied as `.id()` on
    /// `MultiSummonResultView` — forces a fresh view instance (and reset
    /// `@State`) each time, including a same-session repeat pull, so the
    /// staggered reveal always replays from the start.
    @State private var multiResultsSessionID = UUID()

    /// Full-screen "big moment" cutscene, shown for Epic/Legendary pulls only
    /// — the single-pull chest area is small and shares the screen with the
    /// odds panel, which undersells the rarest results. `nil` when no
    /// showcase is active.
    @State private var showcaseResult: SummonResult?

    /// Guards the 10x pull specifically — it's the one button that can burn
    /// a big chunk of gems in a single mis-tap, so it gets a confirmation
    /// step the single 30-gem pull doesn't need.
    @State private var showMultiSummonConfirm = false

    /// Set when the player taps a Dreamkeeper's portrait anywhere in the
    /// summon flow (the result card or the full-screen showcase) — shows
    /// the same full reference page the Codex uses, rather than inventing a
    /// separate info view for this screen.
    @State private var infoDefinition: DreamkeeperDefinition?

    // MARK: - Equipment Summon state
    //
    // A deliberately separate, simpler set of state/effects rather than
    // generalizing the Dreamkeeper reveal state machine above to cover both
    // — this screen has a documented history of subtle SwiftUI compositing
    // bugs (see the RadialGradient and layout-proposal notes throughout),
    // so the existing, already-verified Dreamkeeper flow stays completely
    // untouched. The equipment flow skips the multi-tap escalation ladder
    // and the full-screen showcase cutscene (opens on the first tap) to
    // keep the added surface area small.

    /// The last fully-revealed equipment pull, shown in the side panel.
    @State private var lastEquipmentResult: EquipmentItem?
    /// The in-flight equipment pull: gems already spent and item already
    /// rolled, waiting on the player to tap the chest open.
    @State private var equipmentRevealResult: EquipmentItem?
    @State private var equipmentChestOpened = false
    @State private var equipmentScreenFlashOpacity: Double = 0
    @State private var equipmentImpactRingScale: CGFloat = 0.5
    @State private var equipmentImpactRingOpacity: Double = 0
    @State private var equipmentLegendaryFlash = false
    @State private var equipmentMultiResults: [EquipmentItem] = []
    @State private var showEquipmentMultiResults = false
    @State private var equipmentMultiResultsSessionID = UUID()
    @State private var showEquipmentMultiSummonConfirm = false

    /// Only the tiers `SummonSystem` can actually roll — the escalation
    /// ladder taps walk up one step at a time. Mythic belongs here too: it's
    /// a real, rollable tier (`SummonSystem.rarityOdds` lists it at 2%) —
    /// leaving it out of this ladder used to make `neededTaps` fall through
    /// to 0 for a Mythic pull, bursting the chest open on the very first
    /// tap with no build-up at all for the single rarest possible result.
    private static let tierOrder: [Rarity] = [.uncommon, .rare, .epic, .legendary, .mythic]

    /// Formats an odds-card weight as a percentage — whole numbers stay
    /// bare ("25%"), but Mythic's 0.5% would truncate to a misleading "0%"
    /// through plain `Int(weight * 100)`, so a fractional weight keeps one
    /// decimal place instead.
    private static func oddsPercentText(_ weight: Double) -> String {
        let percent = weight * 100
        if percent == percent.rounded() {
            return "\(Int(percent))%"
        }
        return String(format: "%.1f%%", percent)
    }

    /// Taps needed before the chest bursts open on its own — 2 for the
    /// lowest tier (one tap to start the shake, one to reveal it) up to 5
    /// for legendary, matching "you can tap up to 5 times."
    private var neededTaps: Int {
        guard let result = revealResult, let idx = Self.tierOrder.firstIndex(of: result.definition.rarity) else { return 0 }
        return idx + 2
    }

    /// The rarity hinted at by the current tap count — nil until the second
    /// tap, so the very first tap only shakes the chest with no hint yet.
    private var revealedRarity: Rarity? {
        guard revealResult != nil, tapsSoFar >= 2 else { return nil }
        let idx = min(tapsSoFar - 2, Self.tierOrder.count - 1)
        return Self.tierOrder[idx]
    }

    /// VoiceOver label for the chest — describes the actual result once
    /// opened, invites a tap while a pull is pending, and stays a plain
    /// noun the rest of the time (nothing to do with it between pulls).
    private var chestAccessibilityLabel: String {
        if let revealResult, chestOpened {
            return "\(revealResult.definition.name), \(revealResult.definition.rarity.displayName)"
        } else if revealResult != nil {
            return "Treasure chest, tap to reveal your Dreamkeeper"
        } else {
            return "Treasure chest"
        }
    }

    private var burstColor: Color {
        revealResult?.definition.rarity.primaryColor ?? Theme.gold
    }

    /// Sized to the in-flight pull's rarity from the moment gems are spent —
    /// the particle views need to already exist (centered, invisible) before
    /// `chestOpened` flips, so the outward-fade below can actually animate
    /// the transition instead of just popping the burst in fully formed.
    private var burstParticleCount: Int {
        revealResult?.definition.rarity.summonBurstParticleCount ?? 0
    }

    /// Legendary and Mythic both count as "top tier" for the escalated
    /// effects (flash, wide ray burst, big rarity callout) — Mythic is
    /// strictly rarer than Legendary (2% vs 6%), so it never made sense for
    /// it to get a lesser treatment than the tier right below it.
    private var isTopTierPull: Bool {
        (revealResult?.definition.rarity ?? .common) >= .legendary
    }

    /// The color those top-tier-only effects render in — the pull's own
    /// rarity color rather than a hardcoded gold, so Mythic gets its own
    /// pink/violet treatment instead of looking like a recolored Legendary.
    private var topTierColor: Color {
        revealResult?.definition.rarity.primaryColor ?? Theme.gold
    }

    private var burstRadius: CGFloat { isTopTierPull ? 105 : 58 }
    private var burstDuration: Double { isTopTierPull ? 1.1 : 0.65 }

    // Equipment-flow equivalents of the computed properties above — kept as
    // separate properties (not parameterized versions of the Dreamkeeper
    // ones) for the same untouch-the-existing-flow reason as the state block.

    private var equipmentChestAccessibilityLabel: String {
        if let equipmentRevealResult, equipmentChestOpened {
            return "\(equipmentRevealResult.name), \(equipmentRevealResult.rarity.displayName)"
        } else if equipmentRevealResult != nil {
            return "Treasure chest, tap to reveal your item"
        } else {
            return "Treasure chest"
        }
    }

    private var equipmentBurstColor: Color {
        equipmentRevealResult?.rarity.primaryColor ?? Theme.gold
    }

    private var equipmentBurstParticleCount: Int {
        equipmentRevealResult?.rarity.summonBurstParticleCount ?? 0
    }

    private var equipmentIsTopTierPull: Bool {
        (equipmentRevealResult?.rarity ?? .common) >= .legendary
    }

    private var equipmentTopTierColor: Color {
        equipmentRevealResult?.rarity.primaryColor ?? Theme.gold
    }

    private var equipmentBurstRadius: CGFloat { equipmentIsTopTierPull ? 105 : 58 }
    private var equipmentBurstDuration: Double { equipmentIsTopTierPull ? 1.1 : 0.65 }

    /// The real visible content region (screen bounds minus safe-area
    /// insets), not an implicit ZStack proposal, for the same reason as
    /// `MultiSummonResultView`: this screen was intermittently getting
    /// proposed a height taller than the true visible screen, silently
    /// pushing the header (and its back button) off the top edge with no
    /// consistent trigger ever pinned down. Force-fitting a known-good size
    /// here closes off that whole class of bug for this screen.
    ///
    /// Uses `dk_safeContentSize` rather than raw `UIScreen.main.bounds`:
    /// raw bounds is the *full* panel including the notch / Dynamic Island
    /// and home-indicator strips, so forcing content to it made the layout
    /// taller than the slot `RootView` actually gives this screen — SwiftUI
    /// then centred it and clipped ~10pt off both the top and bottom edges,
    /// which is exactly what cut the back chevron off the top.
    private var screenSize: CGSize { UIScreen.dk_safeContentSize }

    private func isOwned(_ definition: DreamkeeperDefinition) -> Bool {
        gameState.roster.contains { $0.definitionID == definition.id }
    }

    private func ownedCount(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.count
    }

    private func maxStars(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.map(\.stars).max() ?? 0
    }

    var body: some View {
        ZStack {
            // Same lightweight, already-proven-safe twinkling dots used as
            // ambient backdrop across the rest of the app — this screen never
            // had it, so the background sat flat while every other major
            // screen had this bit of depth. Plain opacity-animated `Circle`s
            // under the hood, not a gradient, so it's safe under this
            // screen's compositing rules.
            SparkleField()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                header
                modePicker

                // No ScrollView anywhere in this row on purpose — everything
                // here is sized to actually fit landscape height in one
                // glance instead of requiring a scroll to see the rest.
                // `chestArea`'s size, the button block, and both side cards
                // are all tuned down from their portrait-screen-sized
                // originals specifically so this stays true whether or not
                // a result card is showing alongside the odds card.
                HStack(alignment: .top, spacing: 16) {
                    shrineCard
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 10) {
                        switch summonKind {
                        case .dreamkeeper:
                            if let result = lastResult {
                                resultCard(result)
                            }
                        case .equipment:
                            if let result = lastEquipmentResult {
                                equipmentResultCard(result)
                            }
                        }
                        oddsCard
                    }
                    .frame(width: 300)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxHeight: .infinity)
            }
            // A whole-screen jolt, not just a wiggle on the chest itself —
            // scaled by rarity in `shakeImpact(rarity:)`, this is what
            // actually sells "something big just happened" instead of one
            // more animation confined to a 130pt image.
            .offset(x: shakeOffsetX)
            // This row has no ScrollView on purpose (everything is meant to
            // read in one glance), and its cards are tuned against a
            // landscape iPhone-17-Pro-class safe area. On physically smaller
            // phones that fixed layout would run out of vertical room and
            // clip at the edges, so scale the whole thing down uniformly to
            // fit whatever screen it lands on instead.
            //
            // `maxScale` is held below 1 so the layout also reads a touch
            // more compact (with real margin to the screen edges) even on
            // large phones where it would otherwise sit at full size and
            // feel slightly oversized.
            .adaptiveScale(maxScale: 0.85)

            // A quick full-bleed color wash timed to the chest bursting
            // open, on every pull. A plain solid fill animated by opacity —
            // not a RadialGradient — for the same reason as everywhere else
            // on this screen: that shape has a confirmed history of
            // corrupting this screen's compositing badly enough to silently
            // stop the header from rendering.
            burstColor
                .opacity(screenFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Equipment flow's own flash wash — stays at 0 unless an
            // equipment pull is actually opening, so it's inert while on the
            // Dreamkeeper tab.
            equipmentBurstColor
                .opacity(equipmentScreenFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // An in-place overlay rather than `.fullScreenCover`: presenting
            // and dismissing a genuine modal view controller was leaving this
            // landscape-locked screen's safe-area layout corrupted afterward
            // (the header — including the only way back out — would render
            // off the top edge), so the reveal grid stays in the same view
            // hierarchy instead of triggering a separate presentation.
            if showMultiResults {
                MultiSummonResultView(results: multiResults, gameState: gameState, onRepeat: multiSummon) {
                    showMultiResults = false
                    lastResult = multiResults.max { $0.definition.rarity < $1.definition.rarity }
                }
                // A fresh identity per pull, not just per screen — without
                // this, tapping "Again" would reuse the same view instance
                // and its @State (revealedCount, the best-pull showcase)
                // would never reset, so the new results would just appear
                // already-revealed instead of replaying the grid.
                .id(multiResultsSessionID)
                .zIndex(1)
            }

            if showEquipmentMultiResults {
                EquipmentMultiResultView(results: equipmentMultiResults, gameState: gameState, onRepeat: equipmentMultiSummon) {
                    showEquipmentMultiResults = false
                    lastEquipmentResult = equipmentMultiResults.max { $0.rarity < $1.rarity }
                }
                .id(equipmentMultiResultsSessionID)
                .zIndex(1)
            }

            if let showcaseResult {
                SummonRevealShowcase(result: showcaseResult, onDismiss: {
                    withAnimation(.easeIn(duration: 0.2)) { self.showcaseResult = nil }
                }, onInfoTap: {
                    infoDefinition = showcaseResult.definition
                })
                .zIndex(2)
                .transition(.opacity)
            }

            if let infoDefinition {
                DreamkeeperCodexDetailView(
                    definition: infoDefinition,
                    isOwned: isOwned(infoDefinition),
                    ownedCount: ownedCount(infoDefinition),
                    maxStars: maxStars(infoDefinition),
                    gameState: gameState
                ) {
                    withAnimation(.easeOut(duration: 0.2)) { self.infoDefinition = nil }
                }
                .zIndex(3)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        // A drag-down-to-close gesture as a last-resort exit — on top of the
        // header's own back button and the app-level Dream Haven button in
        // `RootView`, in case a future layout regression on this screen
        // ever hides the header again. `simultaneousGesture` so it never
        // steals the chest tap or the shrineCard ScrollView's own drag-to-
        // scroll; only a sizeable, clearly-downward drag counts, so normal
        // taps and scrolling are unaffected.
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < value.translation.height {
                        navigate(.dreamHaven)
                    }
                }
        )
        .confirmationDialog(
            "Summon 10x?",
            isPresented: $showMultiSummonConfirm,
            titleVisibility: .visible
        ) {
            Button("Summon · \(SummonSystem.multiPullCost) Gems") {
                multiSummon()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This spends \(SummonSystem.multiPullCost) Dream Gems for \(SummonSystem.multiPullTotalCount) Dreamkeepers.")
        }
        .confirmationDialog(
            "Summon 10x?",
            isPresented: $showEquipmentMultiSummonConfirm,
            titleVisibility: .visible
        ) {
            Button("Summon · \(EquipmentSummonSystem.multiPullCost) Gems") {
                equipmentMultiSummon()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This spends \(EquipmentSummonSystem.multiPullCost) Dream Gems for \(EquipmentSummonSystem.multiPullTotalCount) items.")
        }
    }

    private var modePicker: some View {
        Picker("Summon Type", selection: $summonKind) {
            ForEach(SummonKind.allCases) { kind in
                Text(LocalizedStringKey(kind.rawValue)).tag(kind)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 280)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }

    private var header: some View {
        HStack {
            Button {
                navigate(.dreamHaven)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Back")
            Spacer()
            Text("Summoning Shrine")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            RollingGemsPill(amount: gameState.save.dreamGems)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, Theme.violet.opacity(0.35), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(height: 1)
        }
    }

    /// No card, no backing panel — the chest floats directly on the screen
    /// background so it reads as the one thing happening here, not an item
    /// inside a box among other boxes. No ScrollView — `chestArea` and the
    /// button block below are both sized to fit landscape height outright,
    /// so this column never needs scrolling to see its own buttons.
    private var shrineCard: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)

            switch summonKind {
            case .dreamkeeper:
                chestArea
            case .equipment:
                equipmentChestArea
            }

            if summonKind == .dreamkeeper {
                if revealResult == nil {
                    VStack(spacing: 6) {
                        Button {
                            summon()
                        } label: {
                            Label("Summon · \(SummonSystem.cost) Gems", systemImage: "sparkle")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                        .disabled(!gameState.canAffordSummon)

                        Button {
                            showMultiSummonConfirm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("10x Summon · \(SummonSystem.multiPullCost) Gems")
                                Text("+\(SummonSystem.multiPullBonusCount)")
                                    .font(.caption2.weight(.heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.gold.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                        .disabled(!gameState.canAffordMultiSummon)
                    }
                    .frame(width: 260)

                    if !gameState.canAffordSummon {
                        insufficientGemsHint("Not enough Dream Gems.")
                    } else if !gameState.canAffordMultiSummon {
                        insufficientGemsHint("Not enough Gems for 10x.")
                    }
                } else if !chestOpened {
                    VStack(spacing: 6) {
                        Text("Tap the chest to reveal your Dreamkeeper")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))

                        // One dot per tap needed — turns the escalating tap
                        // ladder into visible progress instead of an unknown
                        // number of taps to guess at.
                        HStack(spacing: 5) {
                            ForEach(0..<max(neededTaps, 1), id: \.self) { index in
                                Circle()
                                    .fill(index < tapsSoFar ? Theme.gold : Color.white.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .accessibilityHidden(true)

                        Button("Skip Animation") {
                            skipToReveal()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.softBlue)
                    }
                }
            } else {
                if equipmentRevealResult == nil {
                    VStack(spacing: 6) {
                        Button {
                            equipmentSummon()
                        } label: {
                            Label("Summon · \(EquipmentSummonSystem.cost) Gems", systemImage: "shield.fill")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                        .disabled(!gameState.canAffordEquipmentSummon)

                        Button {
                            showEquipmentMultiSummonConfirm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("10x Summon · \(EquipmentSummonSystem.multiPullCost) Gems")
                                Text("+\(EquipmentSummonSystem.multiPullBonusCount)")
                                    .font(.caption2.weight(.heavy))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.gold.opacity(0.4))
                                    .clipShape(Capsule())
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                        .disabled(!gameState.canAffordEquipmentMultiSummon)
                    }
                    .frame(width: 260)

                    if !gameState.canAffordEquipmentSummon {
                        insufficientGemsHint("Not enough Dream Gems.")
                    } else if !gameState.canAffordEquipmentMultiSummon {
                        insufficientGemsHint("Not enough Gems for 10x.")
                    }
                } else if !equipmentChestOpened {
                    VStack(spacing: 6) {
                        Text("Tap the chest to reveal your item")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))

                        Button("Skip Animation") {
                            skipToEquipmentReveal()
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.softBlue)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }

    /// Shown in place of the summon buttons once the player can't afford
    /// them — a dead-end text label used to be the whole story; this adds
    /// an actual way out, straight to the Shop, instead of making the
    /// player back out and find it themselves.
    @ViewBuilder
    private func insufficientGemsHint(_ text: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
            Button {
                navigate(.shop)
            } label: {
                Label("Get Gems", systemImage: "cart.fill")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.gold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.gold.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityLabel("Go to Shop to buy more Dream Gems")
        }
    }

    private var chestArea: some View {
        ZStack {
            // The big "something huge just happened" flash — Legendary and
            // Mythic only. A blurred solid fill instead of the
            // RadialGradient this used to be: that gradient (like the ones
            // fixed in `MonsterBadge` and `MultiResultTile`) was corrupting
            // this screen's compositing badly enough that the header — the
            // only way back out — would stop rendering afterward, even on a
            // single, non-multi pull.
            if legendaryFlash {
                Circle()
                    .fill(topTierColor)
                    .frame(width: 200, height: 200)
                    .blur(radius: 34)
                    .opacity(0.9)
                    .transition(.opacity)
            }

            // The expanding shockwave ring — every rarity gets one, sized
            // and colored to that pull's own rarity.
            Circle()
                .stroke(burstColor.opacity(impactRingOpacity), lineWidth: isTopTierPull ? 5 : 3)
                .frame(width: isTopTierPull ? 200 : 145, height: isTopTierPull ? 200 : 145)
                .scaleEffect(impactRingScale)

            if let rarity = revealedRarity, !chestOpened {
                Circle()
                    .fill(rarity.primaryColor)
                    .frame(width: 110, height: 110)
                    .blur(radius: 22)
                    .opacity(0.5)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: revealedRarity)

                // Extra shimmer flourish once the hint reaches the top
                // tier(s) — the "goldenes Schimmern" the legendary/mythic
                // tap-stages promise.
                if rarity >= .legendary {
                    ZStack {
                        ForEach(0..<10, id: \.self) { index in
                            let angle = Angle.degrees(Double(index) / 10 * 360)
                            Image(systemName: "sparkle")
                                .font(.subheadline)
                                .foregroundStyle(rarity.primaryColor)
                                .offset(x: cos(angle.radians) * 78, y: sin(angle.radians) * 78)
                        }
                    }
                    .rotationEffect(.degrees(legendaryShimmerSpin ? 360 : 0))
                    .animation(.linear(duration: 2.4).repeatForever(autoreverses: false), value: legendaryShimmerSpin)
                    .onAppear { legendaryShimmerSpin = true }
                }
            }

            // A second, wider, brighter ring of light rays specifically for
            // the top-tier open burst — "richtig krasse Effekte."
            if chestOpened && isTopTierPull {
                ForEach(0..<16, id: \.self) { index in
                    let angle = Angle.degrees(Double(index) / 16 * 360)
                    Capsule()
                        .fill(topTierColor.opacity(0.85))
                        .frame(width: 3.5, height: 50)
                        .offset(y: -72)
                        .rotationEffect(angle)
                        .opacity(legendaryFlash ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: legendaryFlash)
                }
            }

            ForEach(0..<burstParticleCount, id: \.self) { index in
                let angle = Angle.degrees(Double(index) / Double(max(burstParticleCount, 1)) * 360)
                Image(systemName: isTopTierPull && index.isMultiple(of: 3) ? "star.fill" : "sparkle")
                    .font(isTopTierPull ? .title2 : .callout)
                    .foregroundStyle(burstColor)
                    .offset(x: chestOpened ? cos(angle.radians) * burstRadius : 0, y: chestOpened ? sin(angle.radians) * burstRadius : 0)
                    .opacity(chestOpened ? 0 : 1)
                    .animation(.easeOut(duration: burstDuration), value: chestOpened)
            }

            // A soft ambient glow behind the closed, idle chest — between
            // pulls this used to just sit there as a static image; this and
            // the bob below give it a bit of life while waiting for a tap.
            if revealResult == nil {
                Circle()
                    .fill(Theme.gold.opacity(0.16))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .scaleEffect(idlePulse ? 1.12 : 0.88)
                    .opacity(idlePulse ? 0.5 : 0.2)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: idlePulse)
            }

            Image(chestOpened ? "ChestOpen" : "ChestClosed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(wiggle ? 6 : -6))
                .scaleEffect(chestOpened ? (isTopTierPull ? 1.32 : 1.1) : 1.0)
                .offset(y: revealResult == nil ? (idlePulse ? -5 : 5) : 0)
                .shadow(color: (revealedRarity?.primaryColor ?? .clear).opacity(0.75), radius: chestOpened ? (isTopTierPull ? 30 : 20) : 8)
                .animation(.interpolatingSpring(stiffness: 260, damping: 5), value: wiggle)
                .animation(.spring(response: 0.5, dampingFraction: isTopTierPull ? 0.5 : 0.65), value: chestOpened)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: idlePulse)
                .contentShape(Rectangle())
                .onTapGesture { tapChest() }
                .onAppear { idlePulse = true }
                // Silent to VoiceOver before this — the chest is the entire
                // interaction on this screen, so leaving it unlabeled meant
                // a screen-reader user couldn't actually run a summon here.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chestAccessibilityLabel)
                .accessibilityAddTraits(revealResult != nil && !chestOpened ? .isButton : [])
                .accessibilityHint(
                    revealResult != nil && !chestOpened
                        ? "\(max(neededTaps - tapsSoFar, 0)) more taps to open"
                        : ""
                )

            if chestOpened && isTopTierPull {
                Text("\(revealResult?.definition.rarity.displayName.uppercased() ?? "")!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(topTierColor)
                    .shadow(color: topTierColor.opacity(0.8), radius: 8)
                    .offset(y: -88)
                    .opacity(legendaryFlash ? 1 : 0)
                    .scaleEffect(legendaryFlash ? 1 : 0.6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: legendaryFlash)
            }
        }
        // Sized down from this screen's original portrait-first dimensions
        // (was 230/175pt) specifically so the whole shrineCard column — chest
        // plus both summon buttons — fits landscape height without ever
        // needing to scroll to reach the buttons below it.
        .frame(height: 170)
    }

    /// Equipment flow's chest — same asset and the same family of burst/ring/
    /// flash effects as `chestArea`, but opens on the very first tap instead
    /// of an escalating tap ladder, and skips the legendary shimmer flourish
    /// and full-screen showcase — a smaller, single-beat reveal since this
    /// is the newer, lower-risk half of the two flows.
    private var equipmentChestArea: some View {
        ZStack {
            if equipmentLegendaryFlash {
                Circle()
                    .fill(equipmentTopTierColor)
                    .frame(width: 200, height: 200)
                    .blur(radius: 34)
                    .opacity(0.9)
                    .transition(.opacity)
            }

            Circle()
                .stroke(equipmentBurstColor.opacity(equipmentImpactRingOpacity), lineWidth: equipmentIsTopTierPull ? 5 : 3)
                .frame(width: equipmentIsTopTierPull ? 200 : 145, height: equipmentIsTopTierPull ? 200 : 145)
                .scaleEffect(equipmentImpactRingScale)

            if equipmentChestOpened && equipmentIsTopTierPull {
                ForEach(0..<16, id: \.self) { index in
                    let angle = Angle.degrees(Double(index) / 16 * 360)
                    Capsule()
                        .fill(equipmentTopTierColor.opacity(0.85))
                        .frame(width: 3.5, height: 50)
                        .offset(y: -72)
                        .rotationEffect(angle)
                        .opacity(equipmentLegendaryFlash ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: equipmentLegendaryFlash)
                }
            }

            ForEach(0..<equipmentBurstParticleCount, id: \.self) { index in
                let angle = Angle.degrees(Double(index) / Double(max(equipmentBurstParticleCount, 1)) * 360)
                Image(systemName: equipmentIsTopTierPull && index.isMultiple(of: 3) ? "star.fill" : "sparkle")
                    .font(equipmentIsTopTierPull ? .title2 : .callout)
                    .foregroundStyle(equipmentBurstColor)
                    .offset(x: equipmentChestOpened ? cos(angle.radians) * equipmentBurstRadius : 0, y: equipmentChestOpened ? sin(angle.radians) * equipmentBurstRadius : 0)
                    .opacity(equipmentChestOpened ? 0 : 1)
                    .animation(.easeOut(duration: equipmentBurstDuration), value: equipmentChestOpened)
            }

            if equipmentRevealResult == nil {
                Circle()
                    .fill(Theme.gold.opacity(0.16))
                    .frame(width: 150, height: 150)
                    .blur(radius: 30)
                    .scaleEffect(idlePulse ? 1.12 : 0.88)
                    .opacity(idlePulse ? 0.5 : 0.2)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: idlePulse)
            }

            Image(equipmentChestOpened ? "ChestOpen" : "ChestClosed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .scaleEffect(equipmentChestOpened ? (equipmentIsTopTierPull ? 1.32 : 1.1) : 1.0)
                .offset(y: equipmentRevealResult == nil ? (idlePulse ? -5 : 5) : 0)
                .shadow(color: (equipmentRevealResult?.rarity.primaryColor ?? .clear).opacity(0.75), radius: equipmentChestOpened ? (equipmentIsTopTierPull ? 30 : 20) : 8)
                .animation(.spring(response: 0.5, dampingFraction: equipmentIsTopTierPull ? 0.5 : 0.65), value: equipmentChestOpened)
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: idlePulse)
                .contentShape(Rectangle())
                .onTapGesture { tapEquipmentChest() }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(equipmentChestAccessibilityLabel)
                .accessibilityAddTraits(equipmentRevealResult != nil && !equipmentChestOpened ? .isButton : [])

            if equipmentChestOpened && equipmentIsTopTierPull {
                Text("\(equipmentRevealResult?.rarity.displayName.uppercased() ?? "")!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(equipmentTopTierColor)
                    .shadow(color: equipmentTopTierColor.opacity(0.8), radius: 8)
                    .offset(y: -88)
                    .opacity(equipmentLegendaryFlash ? 1 : 0)
                    .scaleEffect(equipmentLegendaryFlash ? 1 : 0.6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: equipmentLegendaryFlash)
            }
        }
        .frame(height: 170)
    }

    /// A horizontal, compact layout on purpose — this used to stack the
    /// portrait above the name/status/rarity, which alone was taller than
    /// this screen's landscape column has room for once `oddsCard` also has
    /// to fit below it without scrolling. Same information, laid out wide
    /// instead of tall.
    private func resultCard(_ result: SummonResult) -> some View {
        let rarityColor = result.definition.rarity.primaryColor
        return GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    if DreamkeeperArt.hasArt(for: result.definition.name) {
                        Image(DreamkeeperArt.assetName(for: result.definition.name))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .shadow(color: result.definition.element.color.opacity(0.7), radius: 10)
                    } else {
                        Circle().fill(result.definition.rarity.gradient).frame(width: 52, height: 52)
                            .shadow(color: result.definition.element.color.opacity(0.7), radius: 10)
                        Image(systemName: result.definition.symbol)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    // Tappable — but small and quiet, so it reads as an
                    // available detail rather than competing with the pull
                    // result itself for attention.
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white, .black.opacity(0.35))
                        .offset(x: 2, y: 2)
                }
                .contentShape(Circle())
                .onTapGesture {
                    gameState.playHaptic(.light)
                    infoDefinition = result.definition
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("View \(result.definition.name) details")

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.definition.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(result.isNew ? "New Dreamkeeper!" : "Already owned · fusion fodder")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(result.isNew ? Theme.gold : .white.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(LocalizedStringKey(result.definition.rarity.displayName))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
        }
        // A blurred solid fill, not a RadialGradient, for the accent wash —
        // this exact screen has a confirmed history of a RadialGradient
        // background corrupting its compositing badly enough to silently
        // stop the header from rendering (see `chestArea` and
        // `MultiResultTile`'s own notes on this). Shadows and plain fills
        // are the fixes already proven safe here.
        .background(
            Circle()
                .fill(rarityColor.opacity(0.3))
                .frame(width: 110, height: 110)
                .blur(radius: 32)
                .offset(x: -70)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(rarityColor.opacity(0.4), lineWidth: 1.25)
        )
        .shadow(color: rarityColor.opacity(0.2), radius: 10, y: 3)
        .transition(.scale.combined(with: .opacity))
    }

    /// Equipment's counterpart to `resultCard` — same compact horizontal
    /// layout and glow-wash treatment, with portrait art where it exists
    /// (falling back to a slot glyph otherwise) and the primary stat bonus
    /// in place of the "new/duplicate" status line. No info-tap affordance:
    /// unlike a Dreamkeeper, an equipment item has no Codex-style reference
    /// page to open.
    private func equipmentResultCard(_ result: EquipmentItem) -> some View {
        let rarityColor = result.rarity.primaryColor
        let statLabel: String
        switch result.slot {
        case .weapon: statLabel = "ATK"
        case .charm: statLabel = "HP"
        case .cloak: statLabel = "DEF"
        case .ring: statLabel = "SPD"
        }
        let statValue = Int(result.statBonus[keyPath: result.slot.primaryStat].rounded())
        return GlassCard {
            HStack(spacing: 12) {
                ZStack {
                    if ItemArt.hasArt(for: result.name) {
                        Image(ItemArt.assetName(for: result.name))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                            .overlay(Circle().strokeBorder(result.rarity.gradient, lineWidth: 2.5))
                            .shadow(color: rarityColor.opacity(0.7), radius: 10)
                    } else {
                        Circle().fill(result.rarity.gradient).frame(width: 52, height: 52)
                            .shadow(color: rarityColor.opacity(0.7), radius: 10)
                        Image(systemName: result.slot.symbol)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(result.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text("+\(statValue) \(statLabel)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                        .lineLimit(1)
                    Text(LocalizedStringKey(result.rarity.displayName))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer(minLength: 0)
            }
        }
        .background(
            Circle()
                .fill(rarityColor.opacity(0.3))
                .frame(width: 110, height: 110)
                .blur(radius: 32)
                .offset(x: -70)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(rarityColor.opacity(0.4), lineWidth: 1.25)
        )
        .shadow(color: rarityColor.opacity(0.2), radius: 10, y: 3)
        .transition(.scale.combined(with: .opacity))
    }

    /// One row of the pity tracker: "Epic+ pity  7/10" with a thin fill bar,
    /// filling gold as `current` approaches `threshold`.
    private func pityProgressRow(label: LocalizedStringKey, current: Int, threshold: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("\(min(current, threshold))/\(threshold)")
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.gold.opacity(0.85))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(Theme.gold)
                        .frame(width: geo.size.width * min(1, Double(current) / Double(threshold)))
                }
            }
            .frame(height: 3)
        }
        .padding(.top, 2)
    }

    private var oddsCard: some View {
        // Rows tightened (spacing 10→6, .caption→.caption2) and the footnote
        // dropped entirely once a result is showing — that's the state where
        // this card has to share the column with `resultCard`, so it's the
        // one that actually needs the saved height; before a pull, this card
        // has the whole column to itself and can afford the explainer.
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Summon Odds")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                ForEach(SummonSystem.rarityOdds, id: \.0) { rarity, weight in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(rarity.primaryColor)
                            .frame(width: 7, height: 7)
                            .accessibilityHidden(true)
                        Text(LocalizedStringKey(rarity.displayName))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                        Spacer()
                        Text(Self.oddsPercentText(weight))
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                // Pity is a real, always-on guarantee (see `SummonSystem`
                // pity thresholds) — shown as plain progress rather than kept
                // as a hidden mechanic, and shared by both summon types since
                // they draw from the same pool.
                pityProgressRow(
                    label: "Epic+ pity",
                    current: gameState.pullsSinceEpicSummon,
                    threshold: SummonSystem.epicPityThreshold
                )
                pityProgressRow(
                    label: "Legendary+ pity",
                    current: gameState.pullsSinceLegendarySummon,
                    threshold: SummonSystem.legendaryPityThreshold
                )
                if summonKind == .dreamkeeper, lastResult == nil {
                    Text("Duplicate pulls join your Inventory — fuse them onto a Dreamkeeper to raise its stars.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 2)
                } else if summonKind == .equipment, lastEquipmentResult == nil {
                    Text("Summoned gear joins your Inventory, sized to your current stage.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.top, 2)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.violet.opacity(0.3), lineWidth: 1.25)
        )
    }

    private func summon() {
        guard let result = gameState.performSummon() else { return }
        tapsSoFar = 0
        chestOpened = false
        gameState.playHaptic(.light)
        revealResult = result
    }

    private func multiSummon() {
        guard let results = gameState.performMultiSummon() else { return }
        gameState.playSound(.summon)
        gameState.playHaptic(.levelUp)
        // Worst-to-best order so the strongest pull "arrives" last in the
        // staggered reveal — a bit of narrative build-up instead of the
        // best card landing at a random spot in the middle.
        multiResults = results.sorted { $0.definition.rarity < $1.definition.rarity }
        multiResultsSessionID = UUID()
        showMultiResults = true
    }

    private func tapChest() {
        guard revealResult != nil, !chestOpened else { return }
        gameState.playHaptic(.light)
        wiggle.toggle()
        tapsSoFar += 1
        if tapsSoFar >= neededTaps {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { openChest() }
        }
    }

    private func skipToReveal() {
        guard revealResult != nil, !chestOpened else { return }
        tapsSoFar = neededTaps
        openChest()
    }

    private func openChest() {
        guard let result = revealResult, !chestOpened else { return }
        let rarity = result.definition.rarity
        let isTopTier = rarity >= .legendary
        let isBigReveal = rarity >= .epic
        gameState.playSound(.summon)
        gameState.playHaptic(.levelUp)
        withAnimation(.spring(response: 0.5, dampingFraction: isTopTier ? 0.5 : 0.7)) {
            chestOpened = true
            lastResult = result
        }

        // Every open gets a jolt now, scaled up by rarity — a Common pull
        // still lands with real punch (screen shake, a quick color flash, a
        // shockwave ring), and Legendary/Mythic stack the full escalated
        // treatment (wide gold/pink ray burst, big rarity callout, full-
        // screen showcase below) on top of that instead of being the only
        // pulls that feel like anything happened at all.
        shakeImpact(rarity: rarity)
        impactRingScale = 0.5
        impactRingOpacity = 0.9
        withAnimation(.easeOut(duration: isBigReveal ? 0.55 : 0.35)) {
            impactRingScale = isBigReveal ? 2.7 : 1.9
            impactRingOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.08)) {
            screenFlashOpacity = isTopTier ? 0.55 : (isBigReveal ? 0.32 : 0.16)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (isTopTier ? 0.16 : 0.08)) {
            withAnimation(.easeOut(duration: isTopTier ? 0.8 : 0.35)) { screenFlashOpacity = 0 }
        }

        if isTopTier {
            withAnimation(.easeOut(duration: 0.12)) { legendaryFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.7)) { legendaryFlash = false }
            }
        }

        // Epic/Legendary/Mythic pulls escalate past the chest's own small effects
        // into a full-screen takeover — the moment worth actually stopping
        // for, rather than one more animation sharing space with the odds
        // panel.
        let waitDuration: Double = isBigReveal ? 2.6 : 1.3
        if isBigReveal {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.25)) { showcaseResult = result }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + waitDuration - 0.3) {
                withAnimation(.easeIn(duration: 0.2)) { showcaseResult = nil }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + waitDuration) {
            revealResult = nil
            chestOpened = false
            tapsSoFar = 0
        }
    }

    private func equipmentSummon() {
        guard let result = gameState.performEquipmentSummon() else { return }
        equipmentChestOpened = false
        gameState.playHaptic(.light)
        equipmentRevealResult = result
    }

    private func equipmentMultiSummon() {
        guard let results = gameState.performEquipmentMultiSummon() else { return }
        gameState.playSound(.summon)
        gameState.playHaptic(.levelUp)
        equipmentMultiResults = results.sorted { $0.rarity < $1.rarity }
        equipmentMultiResultsSessionID = UUID()
        showEquipmentMultiResults = true
    }

    /// Opens on the very first tap — no escalating tap ladder here, unlike
    /// `tapChest` — so this doubles as `skipToEquipmentReveal`'s only step.
    private func tapEquipmentChest() {
        guard equipmentRevealResult != nil, !equipmentChestOpened else { return }
        gameState.playHaptic(.light)
        openEquipmentChest()
    }

    private func skipToEquipmentReveal() {
        tapEquipmentChest()
    }

    private func openEquipmentChest() {
        guard let result = equipmentRevealResult, !equipmentChestOpened else { return }
        let rarity = result.rarity
        let isTopTier = rarity >= .legendary
        let isBigReveal = rarity >= .epic
        gameState.playSound(.summon)
        gameState.playHaptic(.levelUp)
        withAnimation(.spring(response: 0.5, dampingFraction: isTopTier ? 0.5 : 0.7)) {
            equipmentChestOpened = true
            lastEquipmentResult = result
        }

        shakeImpact(rarity: rarity)
        equipmentImpactRingScale = 0.5
        equipmentImpactRingOpacity = 0.9
        withAnimation(.easeOut(duration: isBigReveal ? 0.55 : 0.35)) {
            equipmentImpactRingScale = isBigReveal ? 2.7 : 1.9
            equipmentImpactRingOpacity = 0
        }
        withAnimation(.easeOut(duration: 0.08)) {
            equipmentScreenFlashOpacity = isTopTier ? 0.55 : (isBigReveal ? 0.32 : 0.16)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (isTopTier ? 0.16 : 0.08)) {
            withAnimation(.easeOut(duration: isTopTier ? 0.8 : 0.35)) { equipmentScreenFlashOpacity = 0 }
        }

        if isTopTier {
            withAnimation(.easeOut(duration: 0.12)) { equipmentLegendaryFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.7)) { equipmentLegendaryFlash = false }
            }
        }

        // No showcase escalation for equipment (see the state-block note
        // above) — just a shorter hold before the chest resets for the next
        // pull, roughly matching the Dreamkeeper flow's non-showcase pulls.
        let waitDuration: Double = isBigReveal ? 1.6 : 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + waitDuration) {
            equipmentRevealResult = nil
            equipmentChestOpened = false
        }
    }

    /// A quick decaying jolt across the *whole* screen — not just the chest
    /// — scaled by rarity: barely a nudge for Common, a real "richtig
    /// krasse Effekte" jolt for Legendary/Mythic.
    private func shakeImpact(rarity: Rarity) {
        let amplitude: CGFloat
        switch rarity {
        case .common: amplitude = 4
        case .uncommon: amplitude = 6
        case .rare: amplitude = 9
        case .epic: amplitude = 13
        case .legendary: amplitude = 19
        case .mythic: amplitude = 24
        case .exclusive: amplitude = 30
        }
        let pattern: [CGFloat] = [-1, 0.85, -0.65, 0.45, -0.25, 0.12, 0].map { $0 * amplitude }
        for (index, value) in pattern.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.045) {
                withAnimation(.linear(duration: 0.045)) { shakeOffsetX = value }
            }
        }
    }
}

/// Full-screen "big moment" cutscene for an Epic or Legendary result: dimmed
/// background, rarity-colored light rays, a spinning ring around the
/// portrait, and the rarity/name/"New!" reveal — the celebration a rare pull
/// actually deserves, shared by both the single-pull chest flow and the
/// 10x grid's best-pull highlight. Tap anywhere to dismiss early.
private struct SummonRevealShowcase: View {
    let result: SummonResult
    var onDismiss: () -> Void
    /// Tapping the portrait specifically opens the Dreamkeeper's info page
    /// instead of dismissing the showcase — the portrait's own gesture
    /// wins over the surrounding tap-anywhere-to-dismiss one, so both
    /// behaviors coexist without a mode switch.
    var onInfoTap: (() -> Void)? = nil

    @State private var portraitScale: CGFloat = 0.3
    @State private var portraitOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var titleScale: CGFloat = 0.6
    @State private var titleOpacity: Double = 0
    @State private var rayOpacity: Double = 0
    @State private var rayProgress: CGFloat = 0
    /// A quick white flashbang at the very start of the takeover, and an
    /// expanding shockwave ring right behind it — the "boom" that precedes
    /// the portrait settling into place, rather than everything fading in
    /// at once.
    @State private var flashOpacity: Double = 0
    @State private var shockRingScale: CGFloat = 0.4
    @State private var shockRingOpacity: Double = 0

    private var rarity: Rarity { result.definition.rarity }
    /// Legendary and Mythic both get the biggest version of this showcase —
    /// Mythic is the strictly rarer of the two (2% vs 6%), so it never made
    /// sense for it to render smaller than the tier right below it.
    private var isTopTier: Bool { rarity >= .legendary }
    private var portraitSize: CGFloat { 190 }
    private var hasArt: Bool { DreamkeeperArt.hasArt(for: result.definition.name) }

    /// Glow, light rays, rotating halo and shockwave — all sized and centered
    /// on the portrait and attached to it as a `.background`, so they stay
    /// concentric with it even though the surrounding `VStack` pushes the
    /// portrait above centre to make room for the title beneath.
    private var portraitFX: some View {
        ZStack {
            Circle()
                .fill(rarity.primaryColor.opacity(0.45))
                .frame(width: 300, height: 300)
                .blur(radius: 65)
                .opacity(glowOpacity)

            ForEach(0..<(isTopTier ? 20 : 12), id: \.self) { index in
                let count = isTopTier ? 20 : 12
                let angle = Angle.degrees(Double(index) / Double(count) * 360)
                Capsule()
                    .fill(rarity.primaryColor.opacity(0.75))
                    .frame(width: isTopTier ? 5 : 3.5, height: (isTopTier ? 210 : 140) * rayProgress)
                    .offset(y: -(isTopTier ? 105 : 70) * rayProgress)
                    .rotationEffect(angle)
                    .opacity(rayOpacity)
            }

            RevealRing(diameter: portraitSize + 30, color: rarity.primaryColor, lineWidth: 3,
                       opacity: ringOpacity, rotation: ringRotation, dashCount: 30)

            // The shockwave burst — one plain stroked circle, expanding and
            // fading right as the takeover starts.
            Circle()
                .stroke(rarity.primaryColor.opacity(shockRingOpacity), lineWidth: isTopTier ? 6 : 4)
                .frame(width: 260, height: 260)
                .scaleEffect(shockRingScale)
        }
        .frame(width: 340, height: 340)
        .allowsHitTesting(false)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 16) {
                ZStack {
                    if hasArt {
                        Image(DreamkeeperArt.assetName(for: result.definition.name))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: portraitSize, height: portraitSize)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(rarity.gradient).frame(width: portraitSize, height: portraitSize)
                        Image(systemName: result.definition.symbol)
                            .font(.system(size: portraitSize * 0.4, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay(Circle().strokeBorder(rarity.primaryColor, lineWidth: 5))
                .overlay(alignment: .bottomTrailing) {
                    if onInfoTap != nil {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white, .black.opacity(0.35))
                            .offset(x: 4, y: 4)
                    }
                }
                .shadow(color: rarity.primaryColor.opacity(0.85), radius: isTopTier ? 42 : 34)
                .scaleEffect(portraitScale)
                .opacity(portraitOpacity)
                .background(portraitFX)
                .contentShape(Circle())
                .onTapGesture { onInfoTap?() }

                VStack(spacing: 4) {
                    Text("\(rarity.displayName.uppercased())!")
                        .font(.title.weight(.heavy))
                        .foregroundStyle(rarity.primaryColor)
                        .shadow(color: rarity.primaryColor.opacity(0.8), radius: 10)
                    Text(result.definition.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    if result.isNew {
                        Text("NEW DREAMKEEPER")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10).padding(.vertical, 3)
                            .background(Theme.gold.opacity(0.85))
                            .clipShape(Capsule())
                            .foregroundStyle(.black)
                    }
                }
                .scaleEffect(titleScale)
                .opacity(titleOpacity)
            }
            .offset(y: -6)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .onAppear {
            // The flashbang + shockwave fire first and fade fast, so the
            // portrait/rays/title beneath read as "revealed by the blast"
            // rather than everything materializing together.
            withAnimation(.easeOut(duration: 0.09)) { flashOpacity = isTopTier ? 0.6 : 0.4 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.4)) { flashOpacity = 0 }
            }
            shockRingOpacity = 0.9
            withAnimation(.easeOut(duration: 0.6)) {
                shockRingScale = isTopTier ? 2.6 : 2.0
                shockRingOpacity = 0
            }

            withAnimation(.interpolatingSpring(stiffness: 200, damping: 14)) {
                portraitScale = 1
                portraitOpacity = 1
                glowOpacity = 1
                ringOpacity = 1
            }
            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            rayOpacity = 1
            withAnimation(.easeOut(duration: 0.5)) {
                rayProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    titleScale = 1
                    titleOpacity = 1
                }
            }
        }
    }
}

/// Full-screen reveal grid for the "10+1 free" bulk pull — every result is
/// already rolled by the time this appears, it just pops them in one at a
/// time for a bit of ceremony instead of dumping all 11 in at once.
/// Same look as `ResourcePill`, but the number rolls with SwiftUI's numeric
/// text transition when it changes — spending or earning gems on this screen
/// used to just snap the label to a new value, which read as glitchy rather
/// than deliberate. A local wrapper instead of touching `ResourcePill`
/// itself, since that's shared by every other screen in the app.
private struct RollingGemsPill: View {
    var amount: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .foregroundStyle(Theme.violet)
                .accessibilityHidden(true)
            Text("\(amount)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(amount)))
                .animation(.snappy(duration: 0.5), value: amount)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(
                LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                lineWidth: 1
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(amount) Dream Gems")
    }
}

private struct MultiSummonResultView: View {
    let results: [SummonResult]
    var gameState: GameState
    /// Runs another 10x pull in place — declared before `onContinue` so the
    /// memberwise init keeps `onContinue` as the trailing-closure parameter
    /// at every call site, same as before this was added.
    var onRepeat: () -> Void
    var onContinue: () -> Void

    @State private var revealedCount = 0

    /// A quick screen-wide flash fired each time an Epic+ tile lands during
    /// the staggered reveal — brighter for Legendary+ — so the grid reads as
    /// a sequence of little "hits" building up instead of tiles just quietly
    /// switching on.
    @State private var flashOpacity: Double = 0

    /// The best pull gets its own full-screen showcase once the grid
    /// finishes revealing — otherwise an Epic or Legendary result would be
    /// worth no more ceremony than a Common one, buried as one more tile.
    @State private var showBestShowcase: SummonResult?

    /// Tapping any tile (or the best-pull showcase's portrait) opens this —
    /// same Codex reference page `SummoningShrineView` uses for its own
    /// single-pull result.
    @State private var infoDefinition: DreamkeeperDefinition?

    private func isOwned(_ definition: DreamkeeperDefinition) -> Bool {
        gameState.roster.contains { $0.definitionID == definition.id }
    }

    private func ownedCount(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.count
    }

    private func maxStars(_ definition: DreamkeeperDefinition) -> Int {
        gameState.roster.filter { $0.definitionID == definition.id }.map(\.stars).max() ?? 0
    }

    private var bestRarity: Rarity {
        results.map(\.definition.rarity).max() ?? .common
    }

    private var bestResult: SummonResult? {
        results.first { $0.definition.rarity == bestRarity }
    }

    /// `UIScreen.main.bounds`, not `GeometryReader`, on purpose: this view
    /// kept getting proposed a height taller than the true visible screen
    /// through the ZStack it lives in (pinning the close button in its own
    /// row, then as a zero-height overlay, then even an explicit
    /// `GeometryReader` measurement all still ended up shifted off the top
    /// edge, with the excess as dead space at the bottom) — going straight
    /// to the actual device screen size sidesteps that SwiftUI proposal
    /// chain entirely instead of trying to out-guess it further.
    private var screenSize: CGSize { UIScreen.main.bounds.size }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background

            // Plain solid-color fill, not a gradient — this screen's sibling
            // (SummoningShrineView) has a confirmed history of gradient
            // shapes corrupting SwiftUI's compositing badly enough to break
            // the header underneath, so every flash effect here stays solid.
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)

            ScrollView {
                VStack(spacing: 6) {
                    VStack(spacing: 2) {
                        Text("10x Summon Results")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        if bestRarity >= .epic {
                            (Text("Best Pull: ") + Text(LocalizedStringKey(bestRarity.displayName)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(bestRarity.primaryColor)
                        }
                    }
                    .padding(.top, 14)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 6), spacing: 22) {
                        ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                            MultiResultTile(result: result, revealed: index < revealedCount) {
                                gameState.playHaptic(.light)
                                infoDefinition = result.definition
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Lets a player who's about to do several 10x pulls in a
                    // row stay on this results screen instead of bouncing
                    // back to the shrine and re-confirming every single time.
                    if gameState.canAffordMultiSummon {
                        Button {
                            onRepeat()
                        } label: {
                            Label("Again · \(SummonSystem.multiPullCost) Gems", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                        .frame(width: 220)
                    }

                    Button("Continue", action: onContinue)
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                        .frame(width: 220)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: screenSize.width, height: screenSize.height)

            Button(action: onContinue) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
            .padding(.trailing, 20)
            .padding(.top, 8)

            if let showBestShowcase {
                SummonRevealShowcase(result: showBestShowcase, onDismiss: {
                    withAnimation(.easeIn(duration: 0.2)) { self.showBestShowcase = nil }
                }, onInfoTap: {
                    infoDefinition = showBestShowcase.definition
                })
                .zIndex(2)
                .transition(.opacity)
            }

            if let infoDefinition {
                DreamkeeperCodexDetailView(
                    definition: infoDefinition,
                    isOwned: isOwned(infoDefinition),
                    ownedCount: ownedCount(infoDefinition),
                    maxStars: maxStars(infoDefinition),
                    gameState: gameState
                ) {
                    withAnimation(.easeOut(duration: 0.2)) { self.infoDefinition = nil }
                }
                .zIndex(3)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .ignoresSafeArea()
        // Same drag-down-to-close safety net as the shrine screen behind
        // this one — `simultaneousGesture` so it never competes with the
        // grid's own ScrollView.
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < value.translation.height {
                        onContinue()
                    }
                }
        )
        .onAppear {
            // Each tile popping in gets its own haptic, and Epic+ tiles also
            // punch a screen-wide flash right as they land — without this,
            // an 11-card reveal just quietly fades tiles in one by one with
            // nothing marking the good ones out from the filler.
            for index in 0...results.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        revealedCount = index
                    }
                    guard index > 0 else { return }
                    let justRevealed = results[index - 1].definition.rarity
                    gameState.playHaptic(justRevealed >= .epic ? .levelUp : .light)
                    if justRevealed >= .epic {
                        withAnimation(.easeOut(duration: 0.08)) {
                            flashOpacity = justRevealed >= .legendary ? 0.5 : 0.28
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
                        }
                    }
                }
            }

            if bestRarity >= .epic, let bestResult {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(results.count) * 0.1 + 0.4) {
                    withAnimation(.easeOut(duration: 0.25)) { showBestShowcase = bestResult }
                }
            }
        }
    }
}

private struct MultiResultTile: View {
    let result: SummonResult
    let revealed: Bool
    var onTap: (() -> Void)? = nil

    private var rarity: Rarity { result.definition.rarity }
    private var isRare: Bool { rarity >= .epic }

    private let tileSize: CGFloat = 84

    /// A quick outward-scaling ring burst plus an overshoot "pop" on the
    /// portrait itself, fired the instant this tile flips to revealed — the
    /// plain opacity/scale fade below reads as tiles just quietly switching
    /// on without this.
    @State private var popScale: CGFloat = 1
    @State private var burstScale: CGFloat = 0.6
    @State private var burstOpacity: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(rarity.primaryColor.opacity(burstOpacity), lineWidth: isRare ? 3 : 2)
                    .frame(width: tileSize, height: tileSize)
                    .scaleEffect(burstScale)

                if DreamkeeperArt.hasArt(for: result.definition.name) {
                    Image(DreamkeeperArt.assetName(for: result.definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: tileSize, height: tileSize)
                        .clipShape(Circle())
                } else {
                    Circle().fill(rarity.gradient).frame(width: tileSize, height: tileSize)
                    Image(systemName: result.definition.symbol)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Circle()
                    .strokeBorder(isRare ? Theme.gold.opacity(0.85) : Color.white.opacity(0.15), lineWidth: isRare ? 2.4 : 1.4)
                    .frame(width: tileSize, height: tileSize)
            }
            // A plain shadow glow rather than the RadialGradient this used
            // to be — an oversized gradient shape (90pt) inside a densely
            // populated LazyVGrid, redrawn on every staggered-reveal frame,
            // was corrupting this screen's compositing badly enough that
            // the parent SummoningShrineView's header silently stopped
            // rendering after this view was dismissed. Shadows are cheap
            // and already used the same way for the single-pull result card.
            .shadow(color: isRare ? rarity.primaryColor.opacity(0.75) : .clear, radius: isRare ? 16 : 0)
            .scaleEffect(popScale)

            Text(result.definition.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // A readable rarity tag for Epic+ pulls — the gold border above
            // already hints at it, but a name alone doesn't tell a player
            // *why* a card looks special, especially at a glance across a
            // full 11-card grid.
            if isRare {
                Text(rarity.displayName.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(rarity.primaryColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(rarity.primaryColor.opacity(0.18)))
                    .overlay(Capsule().stroke(rarity.primaryColor.opacity(0.5), lineWidth: 0.75))
            }
        }
        .opacity(revealed ? 1 : 0)
        .scaleEffect(revealed ? 1 : 0.4)
        .contentShape(Rectangle())
        .onTapGesture { if revealed { onTap?() } }
        // One combined stop instead of separate reads for the portrait,
        // name, and rarity tag — and silent entirely while still face-down
        // in the staggered reveal.
        .accessibilityElement(children: revealed ? .combine : .ignore)
        .accessibilityLabel(revealed ? "\(result.definition.name), \(rarity.displayName)\(result.isNew ? ", new" : "")" : "")
        .accessibilityAddTraits(revealed ? .isButton : [])
        .onChange(of: revealed) { _, newValue in
            guard newValue else { return }
            popScale = 1.28
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { popScale = 1 }
            burstOpacity = 0.9
            burstScale = 0.6
            withAnimation(.easeOut(duration: isRare ? 0.55 : 0.35)) {
                burstScale = isRare ? 2.4 : 1.7
                burstOpacity = 0
            }
        }
    }
}

/// Equipment's counterpart to `MultiSummonResultView` — same staggered
/// reveal grid and screen-flash punches, but no full-screen best-pull
/// showcase and no Codex-style info sheet, since equipment has neither.
private struct EquipmentMultiResultView: View {
    let results: [EquipmentItem]
    var gameState: GameState
    var onRepeat: () -> Void
    var onContinue: () -> Void

    @State private var revealedCount = 0
    @State private var flashOpacity: Double = 0

    private var bestRarity: Rarity {
        results.map(\.rarity).max() ?? .common
    }

    private var screenSize: CGSize { UIScreen.main.bounds.size }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.background

            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1)

            ScrollView {
                VStack(spacing: 6) {
                    VStack(spacing: 2) {
                        Text("10x Summon Results")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        if bestRarity >= .epic {
                            (Text("Best Pull: ") + Text(LocalizedStringKey(bestRarity.displayName)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(bestRarity.primaryColor)
                        }
                    }
                    .padding(.top, 14)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 6), spacing: 22) {
                        ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                            EquipmentResultTile(result: result, revealed: index < revealedCount)
                        }
                    }
                    .padding(.horizontal, 20)

                    if gameState.canAffordEquipmentMultiSummon {
                        Button {
                            onRepeat()
                        } label: {
                            Label("Again · \(EquipmentSummonSystem.multiPullCost) Gems", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.violet))
                        .frame(width: 220)
                    }

                    Button("Continue", action: onContinue)
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                        .frame(width: 220)
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: screenSize.width, height: screenSize.height)

            Button(action: onContinue) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
            .padding(.trailing, 20)
            .padding(.top, 8)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .ignoresSafeArea()
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < value.translation.height {
                        onContinue()
                    }
                }
        )
        .onAppear {
            for index in 0...results.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        revealedCount = index
                    }
                    guard index > 0 else { return }
                    let justRevealed = results[index - 1].rarity
                    gameState.playHaptic(justRevealed >= .epic ? .levelUp : .light)
                    if justRevealed >= .epic {
                        withAnimation(.easeOut(duration: 0.08)) {
                            flashOpacity = justRevealed >= .legendary ? 0.5 : 0.28
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) { flashOpacity = 0 }
                        }
                    }
                }
            }
        }
    }
}

private struct EquipmentResultTile: View {
    let result: EquipmentItem
    let revealed: Bool

    private var rarity: Rarity { result.rarity }
    private var isRare: Bool { rarity >= .epic }

    private let tileSize: CGFloat = 84

    @State private var popScale: CGFloat = 1
    @State private var burstScale: CGFloat = 0.6
    @State private var burstOpacity: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(rarity.primaryColor.opacity(burstOpacity), lineWidth: isRare ? 3 : 2)
                    .frame(width: tileSize, height: tileSize)
                    .scaleEffect(burstScale)

                if ItemArt.hasArt(for: result.name) {
                    Image(ItemArt.assetName(for: result.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: tileSize, height: tileSize)
                        .clipShape(Circle())
                } else {
                    Circle().fill(rarity.gradient).frame(width: tileSize, height: tileSize)
                    Image(systemName: result.slot.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Circle()
                    .strokeBorder(rarity.gradient, lineWidth: isRare ? 3 : 2)
                    .frame(width: tileSize, height: tileSize)
            }
            .shadow(color: isRare ? rarity.primaryColor.opacity(0.75) : .clear, radius: isRare ? 16 : 0)
            .scaleEffect(popScale)

            Text(result.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if isRare {
                Text(rarity.displayName.uppercased())
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundStyle(rarity.primaryColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(rarity.primaryColor.opacity(0.18)))
                    .overlay(Capsule().stroke(rarity.primaryColor.opacity(0.5), lineWidth: 0.75))
            }
        }
        .opacity(revealed ? 1 : 0)
        .scaleEffect(revealed ? 1 : 0.4)
        .accessibilityElement(children: revealed ? .combine : .ignore)
        .accessibilityLabel(revealed ? "\(result.name), \(rarity.displayName)" : "")
        .onChange(of: revealed) { _, newValue in
            guard newValue else { return }
            popScale = 1.28
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { popScale = 1 }
            burstOpacity = 0.9
            burstScale = 0.6
            withAnimation(.easeOut(duration: isRare ? 0.55 : 0.35)) {
                burstScale = isRare ? 2.4 : 1.7
                burstOpacity = 0
            }
        }
    }
}
