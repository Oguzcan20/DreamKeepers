import SwiftUI

/// Bundles the Ultimate showcase's caster with whether this cast was a
/// Combo Finisher — kept as one `@State` value so the showcase's Finisher
/// treatment can't drift out of sync with which cast triggered it.
private struct UltimateShowcaseData {
    let combatant: Combatant
    let isFinisher: Bool
}

struct BattleView: View {
    var engine: BattleEngine
    var gameState: GameState
    /// Non-nil only for an Arena Tower fight — swaps the banner's world/stage
    /// text for the floor number instead. `engine.stage` already carries the
    /// floor being fought here (see `GameState.makeArenaBattleEngine`), but a
    /// Campaign-shaped "World N · Stage M" label would be meaningless for it.
    var arenaFloor: Int? = nil
    /// Non-nil only for a Dungeon run — swaps the banner for the dungeon's
    /// name plus a live wave counter (`engine.currentWave`/`totalWaves`)
    /// instead of a stage or floor number.
    var dungeonName: String? = nil
    var onFinished: (BattleEngine) -> Void

    @State private var timer: Timer?
    @State private var showOutcomeOverlay = false
    @State private var shakeAmount: CGFloat = 0
    @State private var ultimateShowcase: UltimateShowcaseData?
    @State private var combatantFrames: [UUID: CGRect] = [:]
    @State private var attackProjectile: AttackProjectile?
    @State private var impactBurst: ImpactBurst?
    @State private var bossFlashColor: Color = .clear
    @State private var bossFlashOpacity: Double = 0
    @State private var comboPulseScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 0) {
            battleBanner

            HStack(alignment: .top, spacing: 0) {
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    if let enemy = engine.activeEnemy {
                        CombatantBanner(combatant: enemy, lastHit: engine.lastHit, lastMechanicTrigger: engine.lastMechanicTrigger)
                    }
                    if engine.comboCount >= 2 {
                        comboCounterView
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: 340)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .frame(maxHeight: .infinity)

            partyRow
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 12)
        }
        .coordinateSpace(name: "battlefield")
        .modifier(ShakeEffect(animatableData: shakeAmount))
        .overlay {
            // The one effect that actually spans both combatants involved: a
            // bolt of the attacker's own element visibly flying from their
            // portrait to the target's the instant a hit lands. This is the
            // unambiguous "who is attacking whom" cue — no per-portrait
            // effect alone can substitute for something that draws the line
            // between the two.
            if let attackProjectile {
                AttackProjectileView(projectile: attackProjectile)
                    .id(attackProjectile.id)
                    .allowsHitTesting(false)
                    .zIndex(1.5)
            }
        }
        .overlay {
            // Where the bolt actually lands: a shockwave ring (doubled for a
            // boss hit or an elemental-advantage hit) so impact reads at the
            // target too, not only as motion along the way there.
            if let impactBurst {
                ImpactBurstView(burst: impactBurst)
                    .id(impactBurst.id)
                    .allowsHitTesting(false)
                    .zIndex(1.4)
            }
        }
        .overlay {
            // A boss landing its own blow gets a brief whole-screen tint in
            // its element's color — the one cue that reads even if the
            // player's eyes are on their own party's HP bars, not the boss's
            // corner of the screen.
            bossFlashColor
                .opacity(bossFlashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .zIndex(1.3)
        }
        .overlay {
            if let showcase = ultimateShowcase {
                UltimateShowcaseView(combatant: showcase.combatant, isFinisher: showcase.isFinisher)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .overlay {
            if showOutcomeOverlay, let outcome = engine.outcome {
                OutcomeOverlay(outcome: outcome) {
                    onFinished(engine)
                }
            }
        }
        .onPreferenceChange(CombatantFramePreferenceKey.self) { combatantFrames = $0 }
        .onChange(of: engine.lastUltimate) { _, newValue in
            gameState.playSound(.ultimate)
            withAnimation(.linear(duration: 0.4)) { shakeAmount += 1 }

            guard let ultimate = newValue,
                  let caster = engine.combatants.first(where: { $0.id == ultimate.casterID }) else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                ultimateShowcase = UltimateShowcaseData(combatant: caster, isFinisher: ultimate.isFinisher)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
                withAnimation(.easeIn(duration: 0.2)) { ultimateShowcase = nil }
            }
        }
        .onChange(of: engine.comboCount) { oldValue, newValue in
            guard newValue > oldValue else { return }
            comboPulseScale = 1.35
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { comboPulseScale = 1 }
        }
        .onChange(of: engine.lastSkillUse) { _, newValue in
            // Fires for both manual taps and Auto-Battle, same as the
            // Ultimate sound above — a short, quiet cast blip.
            guard newValue != nil else { return }
            gameState.playSound(.skill)
        }
        .onChange(of: engine.lastHit) { _, newValue in
            // A much smaller shake than the Ultimate's — just enough that
            // every basic attack lands with a bit of physical weight instead
            // of only the rare ultimates feeling impactful. A boss's own hit
            // gets a visibly heavier jolt, so it reads as a bigger creature
            // landing a bigger blow instead of the same generic tap.
            guard let hit = newValue else { return }
            gameState.playSound(.attack)
            let attacker = engine.combatants.first(where: { $0.id == hit.attackerID })
            let isBossHit = attacker?.isBoss ?? false
            let attackerRole = attacker?.role ?? .damage
            let isBig = hit.isElementAdvantage || isBossHit
            withAnimation(.linear(duration: isBossHit ? 0.24 : 0.15)) { shakeAmount += isBossHit ? 0.4 : 0.18 }

            if isBossHit {
                bossFlashColor = hit.attackerElement.color
                bossFlashOpacity = 0
                withAnimation(.easeOut(duration: 0.08)) { bossFlashOpacity = 0.22 }
                withAnimation(.easeIn(duration: 0.32).delay(0.08)) { bossFlashOpacity = 0 }
            }

            if let startFrame = combatantFrames[hit.attackerID], let endFrame = combatantFrames[hit.targetID] {
                attackProjectile = AttackProjectile(
                    start: CGPoint(x: startFrame.midX, y: startFrame.midY),
                    end: CGPoint(x: endFrame.midX, y: endFrame.midY),
                    color: hit.attackerElement.color,
                    symbol: hit.attackerElement.symbol,
                    big: isBig,
                    role: attackerRole,
                    isBoss: isBossHit
                )
                let flightDuration = isBossHit ? 0.34 : (attackerRole == .tank || attackerRole == .guardian ? 0.24 : 0.2)
                DispatchQueue.main.asyncAfter(deadline: .now() + flightDuration) {
                    attackProjectile = nil
                    impactBurst = ImpactBurst(
                        point: CGPoint(x: endFrame.midX, y: endFrame.midY),
                        color: hit.attackerElement.color,
                        symbol: hit.attackerElement.symbol,
                        big: isBig
                    )
                    let impactLife = isBossHit ? 0.5 : 0.34
                    DispatchQueue.main.asyncAfter(deadline: .now() + impactLife) {
                        impactBurst = nil
                    }
                }
            }
        }
        .onAppear {
            if engine.isBossStage {
                gameState.playSound(.bossEncounter)
            }
            startTicking()
        }
        .onDisappear { timer?.invalidate() }
    }

    /// Blurred so the concept art's own baked-in HUD text/numbers read as
    /// abstract texture instead of competing with our real UI drawn below.
    /// Landscape has almost no vertical room to spare, so this is a thin
    /// accent strip with the stage title overlaid rather than a full banner.
    private var battleBanner: some View {
        Image(engine.isBossStage ? "BossBattleBanner" : "BattleBanner")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .clipped()
            .blur(radius: 4)
            .overlay(
                LinearGradient(colors: [Theme.deepNavy.opacity(0.3), Theme.deepNavy.opacity(0.85)], startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .leading) {
                stageHeader
                    .padding(.horizontal, 20)
            }
            .ignoresSafeArea(edges: .top)
    }

    private var stageHeader: some View {
        HStack {
            Group {
                if let dungeonName {
                    if engine.currentWave == engine.totalWaves {
                        Text("\(dungeonName) · Boss")
                    } else {
                        Text("\(dungeonName) · Wave \(engine.currentWave)/\(engine.totalWaves)")
                    }
                } else if let arenaFloor {
                    Text("Endless Trial · Floor \(arenaFloor)")
                } else {
                    let world = WorldCatalog.world(forStage: engine.stage)
                    let stageInWorld = engine.stage - world.firstStage + 1
                    if engine.isBossStage {
                        Text("\(world.name) · Boss")
                    } else {
                        Text("\(world.name) · \(stageInWorld)/\(World.stagesPerWorld)")
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle((engine.isBossStage || engine.currentWave == engine.totalWaves) ? .red : .white.opacity(0.7))
            Spacer()
            battleControls
        }
    }

    /// Speed (1x/2x) and Auto-Battle toggles — tucked into the banner's
    /// trailing side so repeated stages can be blitzed through without
    /// hunting for a settings screen mid-fight.
    private var battleControls: some View {
        HStack(spacing: 8) {
            Button {
                gameState.setBattleSpeedMultiplier(gameState.battleSpeedMultiplier >= 2.0 ? 1.0 : 2.0)
                gameState.playHaptic(.light)
            } label: {
                Text(gameState.battleSpeedMultiplier >= 2.0 ? "2x" : "1x")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(gameState.battleSpeedMultiplier >= 2.0 ? .black : .white.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(gameState.battleSpeedMultiplier >= 2.0 ? Theme.softBlue : Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .accessibilityLabel(gameState.battleSpeedMultiplier >= 2.0 ? "Battle speed 2x, tap for 1x" : "Battle speed 1x, tap for 2x")

            Button {
                gameState.setAutoBattleEnabled(!gameState.autoBattleEnabled)
                gameState.playHaptic(.light)
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(gameState.autoBattleEnabled ? .black : .white.opacity(0.8))
                    .padding(7)
                    .background(gameState.autoBattleEnabled ? Theme.gold : Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel(gameState.autoBattleEnabled ? "Auto-Battle on" : "Auto-Battle off")
        }
    }

    /// "×N COMBO" pill shown above the enemy once the player has landed at
    /// least 2 hits in a row — momentum made visible, not just a number
    /// tucked in a corner. Turns gold at the Ultimate Finisher threshold so
    /// the player can see exactly when the next Ultimate will hit harder.
    private var comboCounterView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("×\(engine.comboCount) COMBO")
        }
        .font(.caption.weight(.heavy))
        .foregroundStyle(engine.comboCount >= BattleEngine.comboFinisherThreshold ? Theme.gold : .white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(Color.black.opacity(0.45)))
        .overlay(
            Capsule().stroke(engine.comboCount >= BattleEngine.comboFinisherThreshold ? Theme.gold : Color.white.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(comboPulseScale)
    }

    private var partyRow: some View {
        HStack(spacing: 12) {
            ForEach(engine.playerUnits) { combatant in
                // A threatened ally's window to Guard: non-nil only while the
                // enemy is winding up *against this specific ally* — see
                // `Combatant.isTelegraphing`/`.telegraphTargetID`. Counts down
                // from 1 (wind-up just began) to 0 (about to land) so the UI
                // can shrink a ring instead of just showing a flat icon.
                let threatFraction: Double? = {
                    guard let enemy = engine.activeEnemy, enemy.isTelegraphing, enemy.telegraphTargetID == combatant.id else { return nil }
                    return max(0, min(1, enemy.telegraphRemaining / BattleEngine.telegraphDuration))
                }()
                PartyMemberTile(
                    combatant: combatant, lastHit: engine.lastHit, lastSkillUse: engine.lastSkillUse,
                    lastUltimate: engine.lastUltimate, lastTapFeedback: engine.lastTapFeedback,
                    lastChainBurst: engine.lastChainBurst, enemyElement: engine.activeEnemy?.element,
                    threatFraction: threatFraction
                ) {
                    if engine.activateUltimate(for: combatant.id) {
                        gameState.playHaptic(.success)
                    }
                } onSkill: {
                    if engine.activateSkill(for: combatant.id) {
                        gameState.playHaptic(.light)
                    }
                } onPortraitTap: {
                    if threatFraction != nil {
                        if engine.activateGuard(for: combatant.id) {
                            gameState.playHaptic(.light)
                        }
                    } else {
                        switch engine.tapAttack(for: combatant.id) {
                        case .perfect: gameState.playHaptic(.success)
                        case .good: gameState.playHaptic(.light)
                        case .tooEarly, nil: break
                        }
                    }
                }
            }
        }
    }

    private func startTicking() {
        // `Timer.scheduledTimer` alone registers on the run loop's `.default`
        // mode, which UIKit/SwiftUI's touch-tracking suspends while a finger
        // is down — with Active Combat's tap-to-attack and Guard taps, that
        // stalled ticks mid-touch and made the whole fight look choppy,
        // catching up in a burst once the touch ended. Adding `.common`
        // keeps it firing on schedule regardless of any tracking gesture.
        let newTimer = Timer(timeInterval: 0.1, repeats: true) { _ in
            MainActor.assumeIsolated {
                engine.tick(dt: 0.1 * gameState.battleSpeedMultiplier)

                // Auto-Battle: fire every ready Dreamkeeper's Active Skill and
                // Ultimate on its own, the instant each is ready, rather than
                // waiting on a tap — same calls the buttons make.
                if gameState.autoBattleEnabled, engine.outcome == nil {
                    for unit in engine.playerUnits where unit.isAlive {
                        if unit.ultimateReady { engine.activateUltimate(for: unit.id) }
                        if unit.skillReady { engine.activateSkill(for: unit.id) }
                    }
                }

                if engine.outcome != nil {
                    timer?.invalidate()
                    gameState.playHaptic(engine.outcome == .victory ? .success : .warning)
                    if engine.outcome == .victory, engine.isBossStage {
                        gameState.playSound(.bossVictory)
                    }
                    withAnimation(.easeIn(duration: 0.3)) {
                        showOutcomeOverlay = true
                    }
                }
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }
}

/// Enemy portrait + HP. Every basic attack now plays two clearly distinct,
/// element-flavored effect sets on this same view depending on the role it
/// just played in `lastHit`: an "I'm attacking" wind-up/lunge/cast-burst
/// when `attackerID` matches, and an "I got hit" flash/recoil/impact-burst/
/// damage-number when `targetID` matches — so which monster did what is
/// obvious at a glance without any log text.
private struct CombatantBanner: View {
    let combatant: Combatant
    let lastHit: HitEvent?
    let lastMechanicTrigger: MechanicEvent?

    // Being hit.
    @State private var flashOpacity: Double = 0
    @State private var burstColor: Color = .white
    @State private var burstSymbol: String = "sparkle"
    @State private var burstRadius: CGFloat = 0
    @State private var burstOpacity: Double = 0
    @State private var outerBurstRadius: CGFloat = 0
    @State private var outerBurstOpacity: Double = 0
    @State private var shockwaveScale: CGFloat = 0.5
    @State private var shockwaveOpacity: Double = 0
    @State private var recoilScale: CGFloat = 1
    @State private var recoilOffsetY: CGFloat = 0
    @State private var floatingAmount: Int?
    @State private var floatingColor: Color = .white
    @State private var floatingScale: CGFloat = 1
    @State private var floatingOffsetY: CGFloat = 0
    @State private var floatingOpacity: Double = 0

    // Attacking.
    @State private var attackScale: CGFloat = 1
    @State private var attackOffsetY: CGFloat = 0
    @State private var attackTilt: Double = 0
    @State private var attackGlowOpacity: Double = 0
    @State private var castRadius: CGFloat = 0
    @State private var castOpacity: Double = 0
    @State private var cardFlashOpacity: Double = 0

    @State private var mechanicPulseScale: CGFloat = 1
    @State private var mechanicPulseOpacity: Double = 0
    @State private var mechanicLabel: MechanicEvent?

    // Idle presence — a boss keeps visibly "alive" between its own attacks
    // instead of sitting frozen while the party fights it, via a slow
    // breathing scale and a slowly spinning dashed aura ring.
    @State private var bossBreathe: CGFloat = 1
    @State private var bossAuraRotation: Double = 0

    /// Landscape leaves almost no vertical room to spare (see `battleBanner`'s
    /// own comment), so the portrait grows mainly by staying beside the name
    ////HP column rather than stacking above it — width is cheap in the
    /// 300pt-wide sidebar, height is the scarce resource.
    private var portraitSize: CGFloat { 120 }

    /// Name to use for portrait art lookup — `portraitOverrideName` when set
    /// (Arena rivals, see its doc comment), otherwise the combatant's own
    /// display name (campaign monsters/bosses, unchanged behavior).
    private var portraitLookupName: String { combatant.portraitOverrideName ?? combatant.name }
    /// Checks both namespaces: an Arena rival's `portraitOverrideName` names
    /// a real Dreamkeeper, while ordinary enemies only ever have `Monster_`
    /// art. No name ever exists in both catalogs, so this is unambiguous.
    private var hasPortraitArt: Bool {
        DreamkeeperArt.hasArt(for: portraitLookupName) || MonsterArt.hasArt(for: portraitLookupName)
    }
    private var portraitAssetName: String {
        DreamkeeperArt.hasArt(for: portraitLookupName)
            ? DreamkeeperArt.assetName(for: portraitLookupName)
            : MonsterArt.assetName(for: portraitLookupName)
    }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    ZStack {
                        if hasPortraitArt {
                            Image(portraitAssetName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: portraitSize, height: portraitSize)
                                .clipShape(Circle())
                                .overlay(
                                    Circle().strokeBorder(
                                        combatant.isBoss ? Color.red.opacity(0.7) : combatant.element.color.opacity(0.6),
                                        lineWidth: combatant.isBoss ? 3 : 2
                                    )
                                )
                                .shadow(color: (combatant.isBoss ? Color.red : combatant.element.color).opacity(0.5), radius: 14)
                                .overlay(Circle().fill(Color.red.opacity(flashOpacity)))
                        } else {
                            Circle()
                                .fill(combatant.isBoss ? Color.red.opacity(0.35) : combatant.element.color.opacity(0.35))
                                .frame(width: portraitSize, height: portraitSize)
                                .overlay(
                                    Circle().strokeBorder(
                                        combatant.isBoss ? Color.red.opacity(0.7) : combatant.element.color.opacity(0.6),
                                        lineWidth: combatant.isBoss ? 3 : 2
                                    )
                                )
                                .overlay(Circle().fill(Color.red.opacity(flashOpacity)))
                            Image(systemName: combatant.symbol ?? (combatant.isBoss ? "flame.fill" : combatant.element.symbol))
                                .font(.system(size: portraitSize * 0.38, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        // Wind-up: a bright ring plus a fast burst of the
                        // element's own icon punching outward — the clear
                        // "this one is attacking" cue.
                        Circle()
                            .stroke(combatant.element.color, lineWidth: 3.5)
                            .frame(width: portraitSize, height: portraitSize)
                            .blur(radius: 2)
                            .opacity(attackGlowOpacity)
                        ElementBurst(color: combatant.element.color, symbol: combatant.element.symbol, radius: castRadius, opacity: castOpacity, particleCount: 5, particleSize: 11)

                        // Impact: two staggered rings of the attacker's
                        // element icon plus an expanding shockwave — the
                        // clear "this one just got hit" cue.
                        ElementBurst(color: burstColor, symbol: burstSymbol, radius: burstRadius, opacity: burstOpacity, particleCount: 7, particleSize: 10)
                        ElementBurst(color: burstColor, symbol: burstSymbol, radius: outerBurstRadius, opacity: outerBurstOpacity, particleCount: 7, particleSize: 7)
                        Circle()
                            .stroke(burstColor, lineWidth: 2.5)
                            .frame(width: portraitSize, height: portraitSize)
                            .scaleEffect(shockwaveScale)
                            .opacity(shockwaveOpacity)

                        if let mechanic = mechanicLabel?.mechanic {
                            Circle()
                                .stroke(mechanic.triggerColor, lineWidth: 2)
                                .frame(width: portraitSize, height: portraitSize)
                                .scaleEffect(mechanicPulseScale)
                                .opacity(mechanicPulseOpacity)
                        }

                        if combatant.isBoss {
                            RevealRing(diameter: portraitSize + 14, color: .red, lineWidth: 2, opacity: 0.5, rotation: bossAuraRotation, dashCount: 20)
                        }

                        // Wind-up telegraph: a shrinking orange ring that
                        // empties as the real-time countdown to impact runs
                        // out, plus a warning icon — the player's whole cue
                        // that a hit is coming and there's still time to tap
                        // Guard on the threatened ally. Distinct from the
                        // (instant, momentary) "just landed a hit" cue above.
                        if combatant.isTelegraphing {
                            let fraction = max(0, min(1, combatant.telegraphRemaining / BattleEngine.telegraphDuration))
                            Circle()
                                .trim(from: 0, to: fraction)
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: portraitSize + 22, height: portraitSize + 22)
                                .rotationEffect(.degrees(-90))
                                .shadow(color: .orange.opacity(0.7), radius: 6)
                                .animation(.linear(duration: 0.1), value: combatant.telegraphRemaining)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.orange)
                                .shadow(color: .black.opacity(0.5), radius: 3)
                                .offset(y: -(portraitSize / 2) - 18)
                        }
                    }
                    .scaleEffect(attackScale * recoilScale * (combatant.isBoss ? bossBreathe : 1))
                    .offset(y: attackOffsetY + recoilOffsetY)
                    .rotationEffect(.degrees(attackTilt))

                    if let floatingAmount {
                        Text("-\(floatingAmount)")
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(floatingColor)
                            .shadow(color: floatingColor.opacity(0.6), radius: 4)
                            .scaleEffect(floatingScale)
                            .offset(y: floatingOffsetY - 34)
                            .opacity(floatingOpacity)
                    }
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: CombatantFramePreferenceKey.self, value: [combatant.id: proxy.frame(in: .named("battlefield"))])
                    }
                )
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(combatant.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if combatant.isBoss {
                            Text("BOSS")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    // Spells out the enemy's element in text, not just the
                    // portrait ring's tint — the plain-language anchor each
                    // party member's advantage/disadvantage badge below reads
                    // against (see `PartyMemberTile.advantageBadge`).
                    HStack(spacing: 4) {
                        Image(systemName: combatant.element.symbol)
                        Text(LocalizedStringKey(combatant.element.displayName))
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(combatant.element.color)
                    HPBar(fraction: combatant.hpFraction, tint: combatant.isBoss ? .red : Theme.softBlue)
                        .frame(height: 10)
                }
                Spacer(minLength: 0)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(combatant.element.color.opacity(cardFlashOpacity * 0.4))
                .blur(radius: 26)
        )
        .onChange(of: lastHit) { _, newValue in
            guard let hit = newValue else { return }

            if hit.attackerID == combatant.id {
                // A boss winds up bigger, tilts further, and holds the pose
                // longer than a regular attacker — it should read as a much
                // heavier creature landing a much heavier blow, not the same
                // generic tap every other combatant plays. A Healer/Support
                // is never seen swinging in its own kit (only heals/buffs),
                // so its basic attack reads as a cast — a pulsing glow with
                // no lunge — rather than borrowing the melee combatants' hop.
                let isCaster = combatant.role == .healer || combatant.role == .support
                let scale: CGFloat = combatant.isBoss ? 1.38 : (isCaster ? 1.08 : 1.22)
                let tilt: Double = isCaster ? 0 : (combatant.isBoss ? -18 : -10)
                let lift: CGFloat = isCaster ? 0 : (combatant.isBoss ? 20 : 13)
                let windUp: CGFloat = combatant.isBoss ? 62 : (isCaster ? 40 : 46)
                let windUpDuration = combatant.isBoss ? 0.26 : 0.18

                attackGlowOpacity = 1
                castRadius = 0
                castOpacity = 1
                cardFlashOpacity = 1
                withAnimation(.easeOut(duration: windUpDuration)) {
                    attackScale = scale
                    attackTilt = tilt
                    attackOffsetY = lift
                    castRadius = windUp
                    cardFlashOpacity = combatant.isBoss ? 0.9 : 0.75
                }
                withAnimation(.easeOut(duration: 0.28).delay(windUpDuration)) {
                    attackScale = 1
                    attackTilt = 0
                    attackOffsetY = 0
                    attackGlowOpacity = 0
                    castOpacity = 0
                    cardFlashOpacity = 0
                }
            }

            guard hit.targetID == combatant.id else { return }
            let isBig = hit.isElementAdvantage

            flashOpacity = 0.6
            withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0 }

            recoilScale = 0.92
            recoilOffsetY = -10
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                recoilScale = 1
                recoilOffsetY = 0
            }

            burstColor = hit.attackerElement.color
            burstSymbol = hit.attackerElement.symbol
            burstRadius = 0
            burstOpacity = 1
            withAnimation(.easeOut(duration: isBig ? 0.55 : 0.4)) {
                burstRadius = isBig ? 48 : 32
                burstOpacity = 0
            }
            outerBurstRadius = 0
            outerBurstOpacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                outerBurstOpacity = 0.85
                withAnimation(.easeOut(duration: isBig ? 0.6 : 0.45)) {
                    outerBurstRadius = isBig ? 66 : 48
                    outerBurstOpacity = 0
                }
            }

            shockwaveScale = 0.5
            shockwaveOpacity = 0.9
            withAnimation(.easeOut(duration: isBig ? 0.6 : 0.45)) {
                shockwaveScale = isBig ? 1.8 : 1.35
                shockwaveOpacity = 0
            }

            floatingAmount = hit.amount
            floatingColor = isBig ? Theme.gold : .white
            floatingOffsetY = 0
            floatingOpacity = 1
            floatingScale = isBig ? 1.5 : 1.2
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                floatingScale = 1
            }
            withAnimation(.easeOut(duration: 0.85)) {
                floatingOffsetY = -40
                floatingOpacity = 0
            }
        }
        .onChange(of: lastMechanicTrigger) { _, newValue in
            guard let event = newValue, event.targetID == combatant.id else { return }
            mechanicLabel = event
            mechanicPulseScale = 1
            mechanicPulseOpacity = 1
            withAnimation(.easeOut(duration: 0.6)) {
                mechanicPulseScale = 1.6
                mechanicPulseOpacity = 0
            }
        }
        .onAppear {
            guard combatant.isBoss else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bossBreathe = 1.045
            }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                bossAuraRotation = 360
            }
        }
    }
}

/// Collects each combatant portrait's on-screen frame (in the shared
/// "battlefield" coordinate space) so `BattleView` can draw a bolt flying
/// directly between an attacker and its target, wherever either happens to
/// be laid out this frame.
private struct CombatantFramePreferenceKey: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct AttackProjectile: Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let color: Color
    let symbol: String
    let big: Bool
    let role: Role
    let isBoss: Bool
}

/// A glowing bolt of the attacker's own element that visibly travels from
/// the attacker's portrait to the target's the instant a hit lands. Every
/// other effect in this file lives on one portrait or the other — this is
/// the only one that spans both, so it's the clearest possible answer to
/// "who is attacking whom" regardless of how fast the fight moves.
///
/// The flight path itself is shaped by who's attacking rather than being
/// one interchangeable straight line for every combatant: Tanks/Guardians
/// (and the boss, always) throw a heavy overhead arc; Healers/Support lob a
/// gentler curve; everyone else fires a tight, near-straight bolt. A boss's
/// own bolt is bigger, slower, and trails a faint afterimage of itself, so
/// its attacks read as something with real mass landing a real blow.
private struct AttackProjectileView: View {
    let projectile: AttackProjectile

    @State private var progress: CGFloat = 0
    @State private var headOpacity: Double = 0
    @State private var trailOpacity: Double = 0

    private enum Flight { case smash, wave, bolt }

    private var flight: Flight {
        if projectile.isBoss { return .smash }
        switch projectile.role {
        case .tank, .guardian: return .smash
        case .healer, .support: return .wave
        case .damage, .control: return .bolt
        }
    }

    private var duration: Double {
        switch flight {
        case .smash: return projectile.isBoss ? 0.32 : 0.22
        case .wave: return 0.24
        case .bolt: return 0.16
        }
    }

    /// The curve's control-point offset from the straight line, as a
    /// fraction of the travel distance — 0 would just be the old line.
    private var arcFraction: CGFloat {
        switch flight {
        case .smash: return projectile.isBoss ? 0.5 : 0.32
        case .wave: return 0.22
        case .bolt: return 0.08
        }
    }

    private var control: CGPoint {
        let start = projectile.start, end = projectile.end
        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        let dx = end.x - start.x, dy = end.y - start.y
        let length = max(hypot(dx, dy), 1)
        // Perpendicular unit vector, biased to arc upward on screen so a
        // "smash" reads as an overhead swing rather than a sideways dip.
        var perp = CGPoint(x: -dy / length, y: dx / length)
        if perp.y > 0 { perp.x *= -1; perp.y *= -1 }
        let height = length * arcFraction
        return CGPoint(x: mid.x + perp.x * height, y: mid.y + perp.y * height)
    }

    private func curvePoint(_ t: CGFloat) -> CGPoint {
        let mt = 1 - t
        let start = projectile.start, end = projectile.end
        let x = mt * mt * start.x + 2 * mt * t * control.x + t * t * end.x
        let y = mt * mt * start.y + 2 * mt * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }

    private func heading(at t: CGFloat) -> Angle {
        let mt = 1 - t
        let start = projectile.start, end = projectile.end
        let dx = 2 * mt * (control.x - start.x) + 2 * t * (end.x - control.x)
        let dy = 2 * mt * (control.y - start.y) + 2 * t * (end.y - control.y)
        return .radians(Double(atan2(dy, dx)))
    }

    var body: some View {
        let head = curvePoint(progress)
        let lineWidth: CGFloat = flight == .smash ? (projectile.isBoss ? 9 : 6) : (projectile.big ? 5 : 4)

        ZStack {
            Path { path in
                let samples = 18
                path.move(to: projectile.start)
                for i in 1...samples {
                    let t = CGFloat(i) / CGFloat(samples) * progress
                    path.addLine(to: curvePoint(t))
                }
            }
            .stroke(
                LinearGradient(
                    colors: [projectile.color.opacity(0), projectile.color.opacity(0.95)],
                    startPoint: .init(x: 0, y: 0.5), endPoint: .init(x: 1, y: 0.5)
                ),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .opacity(trailOpacity)

            if flight == .smash {
                // A faint afterimage one beat behind the real head — the
                // cheapest way to make something feel heavy rather than
                // fast, without a second real hit or a longer flight.
                Image(systemName: projectile.symbol)
                    .font(.system(size: projectile.isBoss ? 32 : 24, weight: .bold))
                    .foregroundStyle(projectile.color.opacity(0.35))
                    .position(curvePoint(max(0, progress - 0.16)))
                    .opacity(headOpacity)
            }

            Image(systemName: projectile.symbol)
                .font(.system(size: projectile.big ? 30 : 22, weight: .bold))
                .foregroundStyle(projectile.color)
                .shadow(color: projectile.color.opacity(0.9), radius: 10)
                .scaleEffect(projectile.big ? 1.25 : 1)
                .rotationEffect(flight == .bolt ? heading(at: progress) : .zero)
                .position(head)
                .opacity(headOpacity)
        }
        .onAppear {
            headOpacity = 1
            trailOpacity = 1
            withAnimation(.easeIn(duration: duration)) {
                progress = 1
            }
            withAnimation(.easeOut(duration: 0.14).delay(max(0, duration - 0.04))) {
                headOpacity = 0
                trailOpacity = 0
            }
        }
    }
}

private struct ImpactBurst: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
    let symbol: String
    let big: Bool
}

/// Where a bolt actually lands: an expanding ring (doubled for a big hit)
/// plus the element's own icon flashing white-hot at the center — impact
/// now reads at the target, not only as motion along the way there.
private struct ImpactBurstView: View {
    let burst: ImpactBurst

    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0.9
    @State private var iconScale: CGFloat = 0.3
    @State private var iconOpacity: Double = 1

    var body: some View {
        ZStack {
            Circle()
                .stroke(burst.color.opacity(0.85), lineWidth: burst.big ? 5 : 3)
                .frame(width: burst.big ? 92 : 58, height: burst.big ? 92 : 58)
                .scaleEffect(ringScale)
                .opacity(ringOpacity)
            if burst.big {
                Circle()
                    .stroke(burst.color.opacity(0.45), lineWidth: 3)
                    .frame(width: 138, height: 138)
                    .scaleEffect(ringScale)
                    .opacity(ringOpacity * 0.7)
            }
            Image(systemName: burst.symbol)
                .font(.system(size: burst.big ? 26 : 18, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: burst.color.opacity(0.9), radius: 8)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
        }
        .position(burst.point)
        .onAppear {
            withAnimation(.easeOut(duration: burst.big ? 0.44 : 0.3)) {
                ringScale = 1
                ringOpacity = 0
            }
            withAnimation(.easeOut(duration: 0.14)) { iconScale = 1 }
            withAnimation(.easeIn(duration: 0.2).delay(0.12)) { iconOpacity = 0 }
        }
    }
}

/// Small radiating burst tinted and shaped by whichever element is involved
/// — using that element's own symbol (flame/drop/leaf/moon/sparkles) rather
/// than a generic spark, so the effect reads as "fitting the monster"
/// rather than one interchangeable animation for every hit.
private struct ElementBurst: View {
    let color: Color
    var symbol: String = "sparkle"
    let radius: CGFloat
    let opacity: Double
    var particleCount: Int = 6
    var particleSize: CGFloat = 9

    var body: some View {
        ForEach(0..<particleCount, id: \.self) { index in
            let angle = Angle.degrees(Double(index) / Double(particleCount) * 360)
            Image(systemName: symbol)
                .font(.system(size: particleSize, weight: .bold))
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.7), radius: 3)
                .offset(x: cos(angle.radians) * radius, y: sin(angle.radians) * radius)
                .opacity(opacity)
        }
    }
}

private struct PartyMemberTile: View {
    let combatant: Combatant
    let lastHit: HitEvent?
    let lastSkillUse: SkillEvent?
    let lastUltimate: UltimateEvent?
    /// Drives the floating "Perfect!"/"Good"/"Too Early" feedback text after
    /// a tap on this tile's own portrait — see `BattleEngine.tapAttack`.
    let lastTapFeedback: TapFeedbackEvent?
    /// Drives a bonus-hit flourish on this tile when it's the (randomly
    /// chosen) ally a Chain Burst fires from — see
    /// `BattleEngine.triggerChainBurst`.
    let lastChainBurst: ChainBurstEvent?
    /// The single enemy's element (there's only ever one — see
    /// `BattleEngine.pickTarget`), used to badge this Dreamkeeper's own
    /// elemental advantage/disadvantage directly on its portrait instead of
    /// making the player look it up in the Codex mid-fight.
    let enemyElement: Element?
    /// Non-nil only while the enemy is winding up its next attack *against
    /// this specific ally* — counts down from 1 (wind-up just began) to 0
    /// (about to land). Non-nil both gates the shrinking threat ring and
    /// switches what a portrait tap does (Guard instead of tap-attack).
    let threatFraction: Double?
    var onUltimate: () -> Void
    var onSkill: () -> Void
    /// Tapping this ally's own portrait: fires an early basic attack
    /// (`BattleEngine.tapAttack`) normally, or raises Guard
    /// (`BattleEngine.activateGuard`) while `threatFraction` is non-nil —
    /// the dispatch itself lives in `BattleView.partyRow`, this just relays
    /// the tap.
    var onPortraitTap: () -> Void

    // Being hit.
    @State private var flashOpacity: Double = 0
    @State private var burstColor: Color = .white
    @State private var burstSymbol: String = "sparkle"
    @State private var burstRadius: CGFloat = 0
    @State private var burstOpacity: Double = 0
    @State private var outerBurstRadius: CGFloat = 0
    @State private var outerBurstOpacity: Double = 0
    @State private var recoilScale: CGFloat = 1
    @State private var recoilOffsetY: CGFloat = 0
    @State private var floatingAmount: Int?
    @State private var floatingColor: Color = .white
    @State private var floatingScale: CGFloat = 1
    @State private var floatingOffsetY: CGFloat = 0
    @State private var floatingOpacity: Double = 0

    // Attacking.
    @State private var attackScale: CGFloat = 1
    @State private var attackOffsetY: CGFloat = 0
    @State private var attackTilt: Double = 0
    @State private var attackGlowOpacity: Double = 0
    @State private var castRadius: CGFloat = 0
    @State private var castOpacity: Double = 0
    @State private var cardFlashOpacity: Double = 0

    @State private var skillFlashOpacity: Double = 0
    @State private var ultimatePulseScale: CGFloat = 1
    @State private var ultimatePulseOpacity: Double = 0

    // Tap-to-attack feedback ("Perfect!"/"Good"/"Too Early").
    @State private var tapFeedbackText: String?
    @State private var tapFeedbackColor: Color = .white
    @State private var tapFeedbackScale: CGFloat = 1
    @State private var tapFeedbackOffsetY: CGFloat = 0
    @State private var tapFeedbackOpacity: Double = 0

    // Chain Burst — a lighter, orange echo of the Ultimate pulse above.
    @State private var chainBurstPulseScale: CGFloat = 1
    @State private var chainBurstPulseOpacity: Double = 0

    private let portraitSize: CGFloat = 64

    /// Below `BattleEngine.manualTapThreshold`, tapping does nothing but a
    /// "not yet" shake — the ring reads gray. From there to
    /// `perfectTapThreshold` a tap fires a Good early hit — blue. Above that,
    /// a Perfect — gold. Mirrors the tap-quality zones `tapAttack` itself
    /// uses, so the ring is a truthful preview of what a tap right now does.
    private var readinessRingColor: Color {
        if combatant.attackProgress >= BattleEngine.perfectTapThreshold { return Theme.gold }
        if combatant.attackProgress >= BattleEngine.manualTapThreshold { return Theme.softBlue }
        return .white.opacity(0.25)
    }

    /// Small badge shown on the portrait corner when this Dreamkeeper is
    /// strong or weak against the current enemy's element — the same
    /// triangle multiplier `BattleEngine.resolveDamage` already applies,
    /// just made visible during the fight instead of only in the Codex.
    private var advantageBadge: (symbol: String, color: Color)? {
        guard let enemyElement else { return nil }
        let multiplier = combatant.element.multiplier(against: enemyElement)
        if multiplier > 1.0 { return ("arrowtriangle.up.fill", .green) }
        if multiplier < 1.0 { return ("arrowtriangle.down.fill", .red) }
        return nil
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ZStack {
                    if DreamkeeperArt.hasArt(for: combatant.name) {
                        Image(DreamkeeperArt.assetName(for: combatant.name))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: portraitSize, height: portraitSize)
                            .clipShape(Circle())
                            .opacity(combatant.isAlive ? 1 : 0.35)
                            .overlay(Circle().strokeBorder(combatant.element.color.opacity(0.5), lineWidth: 1.5))
                            .overlay(Circle().fill(Color.red.opacity(flashOpacity)))
                            .overlay(Circle().stroke(Theme.softBlue.opacity(skillFlashOpacity), lineWidth: 3))
                    } else {
                        Circle()
                            .fill(combatant.isAlive ? combatant.element.color.opacity(0.35) : Color.white.opacity(0.05))
                            .frame(width: portraitSize, height: portraitSize)
                            .overlay(Circle().strokeBorder(combatant.element.color.opacity(0.5), lineWidth: 1.5))
                            .overlay(Circle().fill(Color.red.opacity(flashOpacity)))
                            .overlay(Circle().stroke(Theme.softBlue.opacity(skillFlashOpacity), lineWidth: 3))
                        Image(systemName: combatant.role.symbol)
                            .font(.system(size: portraitSize * 0.4, weight: .semibold))
                            .foregroundStyle(combatant.isAlive ? .white : .white.opacity(0.3))
                    }
                    // Wind-up glow + fast icon burst when this Dreamkeeper is
                    // the one attacking — mirrors `CombatantBanner`'s cue.
                    Circle()
                        .stroke(combatant.element.color, lineWidth: 3)
                        .frame(width: portraitSize, height: portraitSize)
                        .blur(radius: 1.5)
                        .opacity(attackGlowOpacity)
                    ElementBurst(color: combatant.element.color, symbol: combatant.element.symbol, radius: castRadius, opacity: castOpacity, particleCount: 5, particleSize: 8)

                    // Two staggered impact rings when this Dreamkeeper is hit.
                    ElementBurst(color: burstColor, symbol: burstSymbol, radius: burstRadius, opacity: burstOpacity, particleCount: 6, particleSize: 8)
                    ElementBurst(color: burstColor, symbol: burstSymbol, radius: outerBurstRadius, opacity: outerBurstOpacity, particleCount: 6, particleSize: 6)

                    // Caster's own portrait pops with a gold ring the instant
                    // their ultimate fires — `UltimateShowcaseView` carries the
                    // big moment, this just says "it was you" on the tile too.
                    Circle()
                        .stroke(Theme.gold, lineWidth: 2)
                        .frame(width: portraitSize, height: portraitSize)
                        .scaleEffect(ultimatePulseScale)
                        .opacity(ultimatePulseOpacity)

                    // Same shape, orange, for a Chain Burst bonus hit —
                    // visually "a smaller cousin of the Ultimate pop".
                    Circle()
                        .stroke(Color.orange, lineWidth: 2)
                        .frame(width: portraitSize, height: portraitSize)
                        .scaleEffect(chainBurstPulseScale)
                        .opacity(chainBurstPulseOpacity)

                    if combatant.isAlive, threatFraction == nil {
                        // Attack-readiness ring: color tells the player what
                        // tapping right now would do (see
                        // `readinessRingColor`'s doc comment). Hidden while
                        // threatened — the orange Guard ring below takes over
                        // that space so the two never compete for attention.
                        Circle()
                            .trim(from: 0, to: max(0, min(1, combatant.attackProgress)))
                            .stroke(readinessRingColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: portraitSize + 10, height: portraitSize + 10)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: combatant.attackProgress)
                    }

                    if let threatFraction {
                        // This ally is the enemy's committed target: a
                        // shrinking orange ring is the countdown to impact,
                        // and tapping the portrait now raises Guard instead
                        // of attacking (see `BattleView.partyRow`).
                        Circle()
                            .trim(from: 0, to: threatFraction)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                            .frame(width: portraitSize + 10, height: portraitSize + 10)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .orange.opacity(0.7), radius: 5)
                            .animation(.linear(duration: 0.1), value: threatFraction)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.orange)
                            .padding(4)
                            .background(Circle().fill(Theme.deepNavy.opacity(0.85)))
                            .offset(y: -(portraitSize / 2) - 10)
                    }
                }
                .scaleEffect(attackScale * recoilScale)
                .offset(y: attackOffsetY + recoilOffsetY)
                .rotationEffect(.degrees(attackTilt))
                .onTapGesture { onPortraitTap() }

                if let floatingAmount {
                    Text("-\(floatingAmount)")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(floatingColor)
                        .shadow(color: floatingColor.opacity(0.6), radius: 3)
                        .scaleEffect(floatingScale)
                        .offset(y: floatingOffsetY - 22)
                        .opacity(floatingOpacity)
                }

                if let tapFeedbackText {
                    Text(tapFeedbackText)
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(tapFeedbackColor)
                        .shadow(color: tapFeedbackColor.opacity(0.6), radius: 3)
                        .scaleEffect(tapFeedbackScale)
                        .offset(y: tapFeedbackOffsetY - 22)
                        .opacity(tapFeedbackOpacity)
                }
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: CombatantFramePreferenceKey.self, value: [combatant.id: proxy.frame(in: .named("battlefield"))])
                }
            )
            .overlay(alignment: .topTrailing) {
                if let badge = advantageBadge {
                    Image(systemName: badge.symbol)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(badge.color)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Theme.deepNavy.opacity(0.6), lineWidth: 1))
                        .offset(x: 2, y: -2)
                }
            }

            Text(combatant.name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(combatant.isAlive ? 0.85 : 0.4))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: portraitSize + 12)

            HPBar(fraction: combatant.hpFraction, tint: combatant.element.color)
                .frame(width: portraitSize, height: 6)

            HStack(spacing: 8) {
                Button(action: onSkill) {
                    Image(systemName: "bolt.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(combatant.skillReady ? .black : .white.opacity(0.4))
                        .padding(7)
                        .background(combatant.skillReady ? Theme.softBlue : Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .shadow(color: combatant.skillReady ? Theme.softBlue.opacity(0.8) : .clear, radius: 5)
                }
                .disabled(combatant.activeSkill == nil || !combatant.skillReady || !combatant.isAlive)
                .accessibilityLabel("Active Skill")

                Button(action: onUltimate) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(combatant.ultimateReady ? .black : .white.opacity(0.4))
                        .padding(7)
                        .background(combatant.ultimateReady ? Theme.gold : Color.white.opacity(0.08))
                        .clipShape(Circle())
                        .shadow(color: combatant.ultimateReady ? Theme.gold.opacity(0.8) : .clear, radius: 6)
                }
                .disabled(!combatant.ultimateReady || !combatant.isAlive)
                .accessibilityLabel("Ultimate")
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(combatant.element.color.opacity(cardFlashOpacity * 0.5))
                .blur(radius: 18)
        )
        .opacity(combatant.isAlive ? 1 : 0.4)
        .onChange(of: lastHit) { _, newValue in
            guard let hit = newValue else { return }

            if hit.attackerID == combatant.id {
                // Same "not every attacker plays the same animation" idea as
                // `CombatantBanner`'s enemy side: a Healer/Support never
                // actually swings in its own kit (only heals/buffs), so its
                // basic attack reads as a cast pulse rather than a lunge.
                let isCaster = combatant.role == .healer || combatant.role == .support
                let scale: CGFloat = isCaster ? 1.1 : 1.26
                let tilt: Double = isCaster ? 0 : 10
                let lift: CGFloat = isCaster ? 0 : -12

                attackGlowOpacity = 1
                castRadius = 0
                castOpacity = 1
                cardFlashOpacity = 1
                withAnimation(.easeOut(duration: 0.18)) {
                    attackScale = scale
                    attackTilt = tilt
                    attackOffsetY = lift
                    castRadius = 34
                    cardFlashOpacity = 0.8
                }
                withAnimation(.easeOut(duration: 0.28).delay(0.18)) {
                    attackScale = 1
                    attackTilt = 0
                    attackOffsetY = 0
                    attackGlowOpacity = 0
                    castOpacity = 0
                    cardFlashOpacity = 0
                }
            }

            guard hit.targetID == combatant.id else { return }
            let isBig = hit.isElementAdvantage

            flashOpacity = 0.6
            withAnimation(.easeOut(duration: 0.35)) { flashOpacity = 0 }

            recoilScale = 0.9
            recoilOffsetY = 9
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                recoilScale = 1
                recoilOffsetY = 0
            }

            burstColor = hit.attackerElement.color
            burstSymbol = hit.attackerElement.symbol
            burstRadius = 0
            burstOpacity = 1
            withAnimation(.easeOut(duration: isBig ? 0.45 : 0.35)) {
                burstRadius = isBig ? 36 : 24
                burstOpacity = 0
            }
            outerBurstRadius = 0
            outerBurstOpacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                outerBurstOpacity = 0.8
                withAnimation(.easeOut(duration: isBig ? 0.5 : 0.4)) {
                    outerBurstRadius = isBig ? 48 : 34
                    outerBurstOpacity = 0
                }
            }

            floatingAmount = hit.amount
            floatingColor = isBig ? Theme.gold : .white
            floatingOffsetY = 0
            floatingOpacity = 1
            floatingScale = isBig ? 1.4 : 1.15
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                floatingScale = 1
            }
            withAnimation(.easeOut(duration: 0.7)) {
                floatingOffsetY = -28
                floatingOpacity = 0
            }

            // A guarded hit gets its own callout above the damage number —
            // the number alone (already reduced) wouldn't tell the player
            // *why* it was small, or that their timing mattered.
            if hit.wasGuarded {
                tapFeedbackText = hit.wasPerfectGuard ? "Parried!" : "Blocked!"
                tapFeedbackColor = hit.wasPerfectGuard ? Theme.gold : Theme.softBlue
                tapFeedbackScale = 1.3
                tapFeedbackOffsetY = 0
                tapFeedbackOpacity = 1
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { tapFeedbackScale = 1 }
                withAnimation(.easeOut(duration: 0.8)) {
                    tapFeedbackOffsetY = -34
                    tapFeedbackOpacity = 0
                }
            }
        }
        .onChange(of: lastSkillUse) { _, newValue in
            guard let use = newValue, use.casterID == combatant.id else { return }
            skillFlashOpacity = 0.9
            withAnimation(.easeOut(duration: 0.3)) { skillFlashOpacity = 0 }
        }
        .onChange(of: lastUltimate) { _, newValue in
            guard let ultimate = newValue, ultimate.casterID == combatant.id else { return }
            ultimatePulseScale = 1
            ultimatePulseOpacity = 1
            withAnimation(.easeOut(duration: 0.7)) {
                ultimatePulseScale = 1.5
                ultimatePulseOpacity = 0
            }
        }
        .onChange(of: lastTapFeedback) { _, newValue in
            guard let feedback = newValue, feedback.combatantID == combatant.id else { return }
            switch feedback.quality {
            case .perfect: (tapFeedbackText, tapFeedbackColor) = ("Perfect!", Theme.gold)
            case .good: (tapFeedbackText, tapFeedbackColor) = ("Good!", Theme.softBlue)
            case .tooEarly: (tapFeedbackText, tapFeedbackColor) = ("Too Early", .white.opacity(0.6))
            }
            tapFeedbackScale = 1.25
            tapFeedbackOffsetY = 0
            tapFeedbackOpacity = 1
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { tapFeedbackScale = 1 }
            withAnimation(.easeOut(duration: 0.6)) {
                tapFeedbackOffsetY = -30
                tapFeedbackOpacity = 0
            }
        }
        .onChange(of: lastChainBurst) { _, newValue in
            guard let burst = newValue, burst.casterID == combatant.id else { return }
            chainBurstPulseScale = 1
            chainBurstPulseOpacity = 1
            withAnimation(.easeOut(duration: 0.5)) {
                chainBurstPulseScale = 1.4
                chainBurstPulseOpacity = 0
            }
        }
    }
}

/// Shown once per Ultimate cast: the caster's own portrait scales up big at
/// the center of the screen, circled by a spinning ring, and throws a
/// layered elemental attack burst outward — the primary "something big just
/// happened, and it was them" cue, replacing the old flat screen-tint flash.
/// Purely visual: the (already-visible) party tile shows who it is, so no
/// caption is needed here either.
private struct UltimateShowcaseView: View {
    let combatant: Combatant
    /// True when this cast landed at combo x10+ (`BattleEngine.
    /// comboFinisherThreshold`) and got the damage bonus — shown as a bold
    /// gold "FINISHER!" label plus a heavier ring/glow, so the payoff of
    /// building a combo reads as clearly here as the damage number does.
    var isFinisher: Bool = false

    @State private var portraitScale: CGFloat = 0.3
    @State private var portraitOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var innerStrikeProgress: CGFloat = 0
    @State private var innerStrikeOpacity: Double = 0
    @State private var strikeProgress: CGFloat = 0
    @State private var strikeOpacity: Double = 0

    private var portraitSize: CGFloat { 200 }
    private var hasArt: Bool { DreamkeeperArt.hasArt(for: combatant.name) }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Circle()
                .fill((isFinisher ? Theme.gold : combatant.element.color).opacity(isFinisher ? 0.55 : 0.4))
                .frame(width: isFinisher ? 320 : 280, height: isFinisher ? 320 : 280)
                .blur(radius: 60)
                .opacity(glowOpacity)

            RevealRing(diameter: portraitSize + 34, color: isFinisher ? Theme.gold : combatant.element.color,
                       lineWidth: isFinisher ? 4 : 3, opacity: ringOpacity, rotation: ringRotation, dashCount: 30)

            if isFinisher {
                Text("FINISHER!")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold.opacity(0.8), radius: 8)
                    .offset(y: -(portraitSize / 2) - 46)
                    .opacity(portraitOpacity)
            }

            ZStack {
                if hasArt {
                    Image(DreamkeeperArt.assetName(for: combatant.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: portraitSize, height: portraitSize)
                        .clipShape(Circle())
                } else {
                    Circle().fill(combatant.element.color.opacity(0.45)).frame(width: portraitSize, height: portraitSize)
                    Image(systemName: combatant.role.symbol)
                        .font(.system(size: portraitSize * 0.4, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .overlay(Circle().strokeBorder(combatant.element.color, lineWidth: 5))
            .shadow(color: combatant.element.color.opacity(0.85), radius: 34)
            .scaleEffect(portraitScale)
            .opacity(portraitOpacity)

            // The "attack": an inner fast ring of small icons, followed by
            // a bigger, slower outer ring — two layers punching outward.
            ForEach(0..<8, id: \.self) { index in
                let angle = Angle.degrees(Double(index) / 8 * 360 + 22)
                Image(systemName: combatant.element.symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(combatant.element.color)
                    .offset(x: cos(angle.radians) * 90 * innerStrikeProgress, y: sin(angle.radians) * 90 * innerStrikeProgress)
                    .opacity(innerStrikeOpacity)
            }
            ForEach(0..<10, id: \.self) { index in
                let angle = Angle.degrees(Double(index) / 10 * 360)
                Image(systemName: combatant.element.symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(combatant.element.color)
                    .shadow(color: combatant.element.color.opacity(0.7), radius: 6)
                    .offset(x: cos(angle.radians) * 150 * strikeProgress, y: sin(angle.radians) * 150 * strikeProgress)
                    .opacity(strikeOpacity)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 14)) {
                portraitScale = 1
                portraitOpacity = 1
                glowOpacity = 1
                ringOpacity = 1
            }
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                innerStrikeOpacity = 1
                withAnimation(.easeOut(duration: 0.3)) {
                    innerStrikeProgress = 1
                    innerStrikeOpacity = 0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                strikeOpacity = 1
                withAnimation(.easeOut(duration: 0.5)) {
                    strikeProgress = 1
                    strikeOpacity = 0
                }
            }
        }
    }
}

/// Classic sine-wave screen shake, driven by an ever-increasing counter so
/// each trigger animates a fresh pass regardless of the counter's parity.
private struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

private struct HPBar: View {
    var fraction: Double
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule().fill(tint)
                    .frame(width: geo.size.width * fraction)
                    .animation(.easeOut(duration: 0.2), value: fraction)
            }
        }
        .frame(height: 8)
    }
}

private struct OutcomeOverlay: View {
    let outcome: BattleOutcome
    var onContinue: () -> Void

    @State private var sparkleFall: CGFloat = 0
    @State private var sparkleOpacity: Double = 0
    @State private var vignetteOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            if outcome == .victory {
                VictorySparkleRain(fall: sparkleFall, opacity: sparkleOpacity)
                    .allowsHitTesting(false)
            } else {
                // A flat tint rather than a full-screen RadialGradient — see
                // the fix note on `chestArea` in SummoningShrineView.
                Color.red.opacity(vignetteOpacity * 0.4)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                Group {
                    if outcome == .victory {
                        Text("Victory!")
                    } else {
                        Text("Defeat...")
                    }
                }
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(outcome == .victory ? Theme.gold : .red)
                    .shadow(color: (outcome == .victory ? Theme.gold : .red).opacity(0.6), radius: 12)

                Button("Continue") { onContinue() }
                    .buttonStyle(PrimaryButtonStyle(tint: outcome == .victory ? Theme.violet : .gray))
                    .frame(width: 200)
            }
            .transition(.scale.combined(with: .opacity))
        }
        .onAppear {
            if outcome == .victory {
                sparkleOpacity = 1
                withAnimation(.easeOut(duration: 1.4)) {
                    sparkleFall = 1
                }
            } else {
                withAnimation(.easeIn(duration: 0.5)) {
                    vignetteOpacity = 0.5
                }
            }
        }
    }
}

/// A handful of gold sparkles drifting down from the top of the screen on
/// victory — a quick celebratory flourish beyond the plain text fade.
private struct VictorySparkleRain: View {
    let fall: CGFloat
    let opacity: Double

    private let particles: [(x: CGFloat, delay: Double, scale: CGFloat)] = (0..<14).map { index in
        (x: CGFloat.random(in: 0.05...0.95), delay: Double(index % 5) * 0.08, scale: CGFloat.random(in: 0.6...1.2))
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles.indices, id: \.self) { index in
                let particle = particles[index]
                Image(systemName: "sparkle")
                    .font(.system(size: 14 * particle.scale))
                    .foregroundStyle(Theme.gold)
                    .position(x: geo.size.width * particle.x, y: geo.size.height * fall * (1 - particle.delay) )
                    .opacity(opacity)
            }
        }
        .ignoresSafeArea()
    }
}
