import SwiftUI

/// Shown once, right after `OnboardingView` finishes — lets the player pick
/// an element for their starter Olf. Holding the Ember option for 5 full
/// seconds instead of tapping it is a deliberately undocumented shortcut to
/// "Ultimate Olf" (+10% to every stat over a normal Olf); nothing on screen
/// spells that out, matching the request for an actual secret rather than a
/// hinted one. `RootView` overlays this atop Dream Haven while
/// `gameState.needsStarterOlfChoice` is true, and `onChoose` — wired to
/// `GameState.chooseStarterOlf(element:)` — passes `nil` for the Ultimate
/// Olf case and a real `Element` for every normal tap.
///
/// This is the player's first real look at Olf, so the whole screen — not
/// a small floating card — is given over to the moment: a circular "portal"
/// wipe opens the scene instead of a plain fade, a short piece of lore
/// explains why this choice exists at all, and the reveal cascades in
/// (hero → title → lore → tiles) rather than appearing all at once.
struct StarterOlfChoiceView: View {
    var onChoose: (Element?) -> Void

    @State private var resolved = false
    @State private var emberHoldProgress: Double = 0
    /// Whichever tile is currently pressed down (not yet released) — tints
    /// the hero portrait's glow toward that element as a live preview, so
    /// the choice feels connected to Olf himself rather than to a button.
    @State private var pressedElement: Element?
    /// Toggled once on appear and left `true` forever — paired with
    /// `.repeatForever` animations for the halo/sparkle rings, matching the
    /// `legendaryShimmerSpin`/`idlePulse` idiom used by `SummoningShrineView`.
    @State private var heroSpin = false
    @State private var heroBreathe = false
    /// Set the instant a choice lands; briefly holds the screen on a bright
    /// confirmation flash before `onChoose` actually fires, so committing to
    /// an element reads as a small event rather than an instant screen swap.
    @State private var flashActive = false

    /// Drives the ambient dust motes drifting across the backdrop — a single
    /// shared toggle, staggered per-mote via each mote's own `.delay`, so one
    /// state flip is enough to keep two dozen particles independently alive.
    @State private var ambientDrift = false
    /// The "portal" the whole scene opens through: an inscribed circle
    /// scaled from a pinprick up past the screen's corners. Using `.mask`
    /// with a scaling `Circle` is the classic SwiftUI iris-wipe — cheap,
    /// and reads as something *opening* rather than merely fading in.
    @State private var portalMaskScale: CGFloat = 0.0001
    @State private var shockwaveScale: CGFloat = 0.4
    @State private var shockwaveOpacity: Double = 0.95
    /// Coarse reveal clock for the cascade — 0 before anything has
    /// happened, climbing to 4 as the hero, then the title, then the lore,
    /// then the element tiles each get their turn. Every dependent view
    /// animates off changes to this single Int instead of juggling its own
    /// timer, so the whole sequence stays easy to re-time in one place.
    @State private var revealStage = 0

    /// Which element was actually committed (`nil` = the secret Ultimate
    /// Olf) — captured the instant a tile resolves so the recruit-reveal
    /// screen below can look up the right `DreamkeeperDefinition` without
    /// re-deriving it from `onChoose`'s own argument later.
    @State private var committedElement: Element?
    @State private var committedDefinition: DreamkeeperDefinition?
    /// Second act: once the confirmation flash fades, this takes over the
    /// whole screen with a proper "you've recruited someone" moment instead
    /// of handing off to `onChoose` — and therefore Dream Haven — the
    /// instant a tile is tapped.
    @State private var showRecruitReveal = false

    private let holdDuration: TimeInterval = 5
    private let confirmDelay: TimeInterval = 0.45

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                ZStack {
                    backdrop
                    ambientField(in: geo.size)
                    content
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .mask(Circle().scaleEffect(portalMaskScale))

                shockwaveRing
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                if showRecruitReveal, let definition = committedDefinition {
                    OlfRecruitRevealView(definition: definition, element: committedElement) {
                        onChoose(committedElement)
                    }
                    .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .onAppear { runOpeningSequence() }
    }

    // MARK: - Opening sequence

    private func runOpeningSequence() {
        withAnimation(.easeOut(duration: 1.05)) { portalMaskScale = 6 }
        withAnimation(.easeOut(duration: 0.85)) {
            shockwaveScale = 16
            shockwaveOpacity = 0
        }
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { heroSpin = true }
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { heroBreathe = true }
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { ambientDrift = true }

        for (index, delay) in [0.28, 0.5, 0.72, 0.94].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.5)) { revealStage = index + 1 }
            }
        }
    }

    // MARK: - Backdrop & ambience

    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.midnightPurple, Theme.deepNavy, .black],
                startPoint: .top, endPoint: .bottom
            )
            RadialGradient(
                colors: [heroGlowColor.opacity(0.32), .clear],
                center: .center, startRadius: 20, endRadius: 480
            )
            .blendMode(.plusLighter)
            .animation(.easeOut(duration: 0.4), value: pressedElement)
        }
        .ignoresSafeArea()
    }

    private struct AmbientMote: Identifiable {
        let id: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let duration: Double
        let delay: Double
    }

    /// A fixed, deterministically-generated field of dust motes — computed
    /// once from a plain integer hash rather than `Double.random`, so the
    /// scattering is stable across every re-render instead of reshuffling
    /// itself on every state change.
    private static let ambientMotes: [AmbientMote] = (0..<26).map { i in
        var seed = UInt64(i &* 2_654_435_761 &+ 40_503)
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 40) % 1000) / 1000
        }
        return AmbientMote(
            id: i,
            x: CGFloat(next()),
            y: CGFloat(next()),
            size: CGFloat(1.5 + next() * 3.5),
            duration: 4 + next() * 5,
            delay: next() * 3.5
        )
    }

    private func ambientField(in size: CGSize) -> some View {
        ZStack {
            ForEach(Self.ambientMotes) { mote in
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: mote.size, height: mote.size)
                    .position(x: mote.x * size.width, y: mote.y * size.height)
                    .offset(y: ambientDrift ? -16 : 8)
                    .opacity(ambientDrift ? 0.75 : 0.12)
                    .animation(
                        .easeInOut(duration: mote.duration).repeatForever(autoreverses: true).delay(mote.delay),
                        value: ambientDrift
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The energy ring that rides just ahead of the portal wipe — unmasked,
    /// so it's visible against the still-black screen for the instant
    /// before the mask itself catches up and reveals everything behind it.
    private var shockwaveRing: some View {
        Circle()
            .strokeBorder(
                AngularGradient(colors: [Theme.gold, .white, Theme.gold, .white], center: .center),
                lineWidth: 3
            )
            .frame(width: 46, height: 46)
            .scaleEffect(shockwaveScale)
            .opacity(shockwaveOpacity)
            .blur(radius: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    // MARK: - Layout

    private var content: some View {
        HStack(alignment: .center, spacing: 28) {
            heroColumn
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1)
                .padding(.vertical, 36)
            choiceColumn
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heroColumn: some View {
        VStack(spacing: 10) {
            VStack(spacing: 4) {
                Text("THE FIRST BOND")
                    .font(.system(size: 11, weight: .bold))
                    .kerning(2.4)
                    .foregroundStyle(Theme.gold.opacity(0.85))
                    .opacity(revealStage >= 2 ? 1 : 0)
                    .offset(y: revealStage >= 2 ? 0 : 8)
                    .animation(.easeOut(duration: 0.5), value: revealStage)

                Text("Olf Has Chosen You")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(revealStage >= 2 ? 1 : 0)
                    .offset(y: revealStage >= 2 ? 0 : 10)
                    .animation(.easeOut(duration: 0.5).delay(0.05), value: revealStage)
            }

            heroPortrait
                .opacity(revealStage >= 1 ? 1 : 0)
                .scaleEffect(revealStage >= 1 ? 1 : 0.7)
                .animation(.spring(response: 0.55, dampingFraction: 0.72), value: revealStage)

            Text("Every Dreamkeeper bonds with a dreamwalker sooner or later — but Olf came to you unclaimed, before Dream Haven even opened its gates. The element you choose now will shape him for as long as he walks beside you.")
                .font(.system(size: 12.5))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300)
                .opacity(revealStage >= 3 ? 1 : 0)
                .offset(y: revealStage >= 3 ? 0 : 8)
                .animation(.easeOut(duration: 0.5), value: revealStage)

            Text("This choice is permanent.")
                .font(.system(size: 11, weight: .semibold))
                .italic()
                .foregroundStyle(.white.opacity(0.45))
                .opacity(revealStage >= 4 ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: revealStage)
        }
    }

    private var choiceColumn: some View {
        VStack(spacing: 16) {
            Text("PICK HIS ELEMENT")
                .font(.system(size: 11, weight: .bold))
                .kerning(2)
                .foregroundStyle(.white.opacity(0.5))
                .opacity(revealStage >= 3 ? 1 : 0)
                .animation(.easeOut(duration: 0.4), value: revealStage)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                ForEach(Array(Element.allCases.enumerated()), id: \.offset) { index, element in
                    Group {
                        if element == .ember {
                            emberTile
                        } else {
                            elementTile(element)
                        }
                    }
                    .opacity(revealStage >= 4 ? 1 : 0)
                    .offset(y: revealStage >= 4 ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.07), value: revealStage)
                }
            }
            .frame(maxWidth: 360)
        }
    }

    // MARK: - Hero portrait

    /// The glow's color previews whichever element is currently pressed
    /// (falling back to a neutral gold while nothing is pressed) — a quiet
    /// hint that the portrait is reacting to the player's choice in real
    /// time, not just decoration sitting above the grid.
    private var heroGlowColor: Color {
        pressedElement?.color ?? Theme.gold
    }

    private var heroPortrait: some View {
        ZStack {
            Circle()
                .fill(heroGlowColor.opacity(0.4))
                .frame(width: 172, height: 172)
                .blur(radius: 32)
                .scaleEffect(heroBreathe ? 1.14 : 0.92)
                .opacity(heroBreathe ? 0.9 : 0.55)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: heroBreathe)
                .animation(.easeOut(duration: 0.35), value: pressedElement)

            // Slow-spinning ring of light rays behind the portrait, purely
            // ambient — so this reads as alive rather than a static picture
            // sitting above a row of buttons.
            ForEach(0..<10, id: \.self) { index in
                let baseAngle = Angle.degrees(Double(index) / 10 * 360)
                Capsule()
                    .fill(heroGlowColor.opacity(0.55))
                    .frame(width: 3, height: 18)
                    .offset(y: -92)
                    .rotationEffect(baseAngle + .degrees(heroSpin ? 360 : 0))
                    .animation(.linear(duration: 16).repeatForever(autoreverses: false), value: heroSpin)
                    .animation(.easeOut(duration: 0.35), value: pressedElement)
            }

            // A second, faster ring spinning the opposite way for a bit of
            // parallax rather than everything moving as one flat disc.
            ForEach(0..<6, id: \.self) { index in
                let baseAngle = Angle.degrees(Double(index) / 6 * 360)
                Image(systemName: "sparkle")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(y: -82)
                    .rotationEffect(baseAngle + .degrees(heroSpin ? -360 : 0))
                    .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: heroSpin)
            }

            // The portrait itself — Olf's actual art rather than an icon
            // badge, since this is the first time the player meets him by
            // name. Falls back to a badge if the art is ever missing, same
            // gate `DreamkeeperArt` uses everywhere else.
            Group {
                if DreamkeeperArt.hasArt(for: "Olf") {
                    Image(DreamkeeperArt.assetName(for: "Olf"))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        Circle().fill(Theme.gold.opacity(0.3))
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 118, height: 118)
            .clipShape(Circle())
            .overlay(
                Circle().strokeBorder(
                    AngularGradient(
                        colors: [heroGlowColor, .white.opacity(0.85), heroGlowColor],
                        center: .center
                    ),
                    lineWidth: 3
                )
            )
            .shadow(color: heroGlowColor.opacity(0.7), radius: 20)
            .scaleEffect(heroBreathe ? 1.03 : 1)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: heroBreathe)
            .animation(.easeOut(duration: 0.3), value: pressedElement)

            // The secret Ember hold charges this same halo instead of only
            // the thin bar under the tile — by the time the hold completes
            // the whole portrait is glowing white-hot, which sells "Olf just
            // became something else" the instant Ultimate Olf is granted.
            if emberHoldProgress > 0 {
                Circle()
                    .stroke(Color.white.opacity(0.9), lineWidth: 4)
                    .frame(width: 118, height: 118)
                    .scaleEffect(1 + emberHoldProgress * 0.4)
                    .opacity(emberHoldProgress)
                    .blur(radius: 2)
            }

            // A bright expanding ring on the instant a choice lands — the
            // beat that sells "confirmed" before the screen goes away.
            if flashActive {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.95), .clear],
                            center: .center, startRadius: 0, endRadius: 105
                        )
                    )
                    .frame(width: 210, height: 210)
                    .scaleEffect(flashActive ? 1.3 : 0.35)
                    .opacity(flashActive ? 0 : 1)
                    .animation(.easeOut(duration: confirmDelay), value: flashActive)
            }
        }
        .frame(height: 190)
        // Decorative — the element names/labels on the tiles below already
        // convey everything a VoiceOver user needs to make the choice.
        .accessibilityHidden(true)
    }

    // MARK: - Element tiles

    private func elementTile(_ element: Element) -> some View {
        Button {
            choose(element)
        } label: {
            elementTileLabel(element)
        }
        .buttonStyle(GlowingTileButtonStyle(element: element, pressedElement: $pressedElement))
        .disabled(resolved)
    }

    /// The Ember tile carries the secret: a plain tap still picks Ember
    /// normally, but holding it down for `holdDuration` fires `perform`
    /// instead and the release that follows is swallowed by `resolved`
    /// already being true — so the player never also gets a normal Ember
    /// pick immediately after unlocking the ultimate one.
    private var emberTile: some View {
        elementTileLabel(.ember)
            .scaleEffect(pressedElement == .ember && !resolved ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: pressedElement)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(Element.ember.color.opacity(0.9))
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: emberHoldProgress, y: 1, anchor: .leading)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 6)
                    .opacity(emberHoldProgress > 0 ? 1 : 0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                choose(.ember)
            }
            .onLongPressGesture(minimumDuration: holdDuration, maximumDistance: 60) {
                guard !resolved else { return }
                resolved = true
                withAnimation(.easeOut(duration: 0.15)) { emberHoldProgress = 1 }
                confirm(nil)
            } onPressingChanged: { isPressing in
                guard !resolved else { return }
                pressedElement = isPressing ? .ember : nil
                if isPressing {
                    withAnimation(.linear(duration: holdDuration)) { emberHoldProgress = 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { emberHoldProgress = 0 }
                }
            }
    }

    private func elementTileLabel(_ element: Element) -> some View {
        let isPressed = pressedElement == element
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [element.color.opacity(0.55), element.color.opacity(0.18)],
                            center: .center, startRadius: 0, endRadius: 32
                        )
                    )
                    .frame(width: 58, height: 58)
                    .shadow(color: element.color.opacity(isPressed ? 0.85 : 0.5), radius: isPressed ? 16 : 10)
                Circle()
                    .strokeBorder(element.color.opacity(isPressed ? 0.9 : 0.35), lineWidth: isPressed ? 2.5 : 1.5)
                    .frame(width: 58, height: 58)
                Image(systemName: element.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .scaleEffect(isPressed ? 1.12 : 1)
            }
            .animation(.easeOut(duration: 0.15), value: isPressed)
            Text(element.displayName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [element.color.opacity(isPressed ? 0.28 : 0.14), Color.white.opacity(0.05)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(element.color.opacity(isPressed ? 0.55 : 0.18), lineWidth: isPressed ? 1.5 : 1)
        )
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(element.displayName)
    }

    // MARK: - Committing a choice

    private func choose(_ element: Element) {
        guard !resolved else { return }
        resolved = true
        pressedElement = element
        confirm(element)
    }

    /// Plays the confirmation flash, then — instead of handing off to
    /// `onChoose` right away and dumping the player straight into Dream
    /// Haven — brings up `OlfRecruitRevealView`. `onChoose` only fires once
    /// the player dismisses that screen; `resolved` is already `true` by
    /// the time either caller reaches this, so no input landing during the
    /// delay can fire a second choice.
    private func confirm(_ element: Element?) {
        committedElement = element
        let definitionID = element.map(DreamkeeperCatalog.olfDefinitionID(for:)) ?? DreamkeeperCatalog.ultimateOlfID
        committedDefinition = DreamkeeperCatalog.starter.definition(for: definitionID)
        withAnimation(.easeOut(duration: confirmDelay)) { flashActive = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + confirmDelay) {
            withAnimation(.easeOut(duration: 0.35)) { showRecruitReveal = true }
        }
    }
}

/// The second act of the starter-choice moment: a full-screen "you've just
/// recruited someone" takeover — flashbang, expanding shockwave, a rotating
/// dashed ring and a burst of rays around the real Olf portrait, followed by
/// an actual readout of who this Olf is (element, Ultimate, Active Skill,
/// Passive, flavor text) — instead of the old behavior of just fading
/// straight into Dream Haven's inventory the instant a tile was tapped.
/// Landscape two-column layout to match the rest of this screen; tapping
/// anywhere (or the Continue button) fires `onContinue`, which is when the
/// caller actually applies the choice via `GameState.chooseStarterOlf`.
private struct OlfRecruitRevealView: View {
    let definition: DreamkeeperDefinition
    /// `nil` marks the secret Ultimate Olf — gets its own gold "secret
    /// unlocked" framing instead of a plain element badge.
    let element: Element?
    var onContinue: () -> Void

    private var isUltimate: Bool { element == nil }
    private var accentColor: Color { element?.color ?? Theme.gold }
    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }

    @State private var flashOpacity: Double = 0
    @State private var shockRingScale: CGFloat = 0.4
    @State private var shockRingOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringOpacity: Double = 0
    @State private var rayOpacity: Double = 0
    @State private var rayProgress: CGFloat = 0
    @State private var portraitScale: CGFloat = 0.4
    @State private var portraitOpacity: Double = 0
    /// Coarse reveal clock for the info side, mirroring the parent screen's
    /// own `revealStage` idiom — 0 before anything, climbing to 4 as the
    /// eyebrow/title, element badge, ability list, then the continue prompt
    /// each get their turn.
    @State private var infoStage = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()

            // A soft screen-wide wash from the portrait's side of the layout —
            // the concentric glow/rays/rings that actually frame Olf are
            // attached to the portrait itself (see `portraitFX`), so they can
            // never drift away from it.
            RadialGradient(colors: [accentColor.opacity(0.28), .clear], center: .center, startRadius: 20, endRadius: 520)
                .opacity(glowOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            Color.white.opacity(flashOpacity).ignoresSafeArea().allowsHitTesting(false)

            HStack(alignment: .center, spacing: 36) {
                portraitColumn
                infoColumn
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .accessibilityAddTraits(.isModal)
        .onAppear { runSequence() }
    }

    /// Everything that frames the portrait, sized and centered on the portrait
    /// itself so it stays glued to it regardless of where the surrounding
    /// two-column layout places the portrait.
    private var portraitFX: some View {
        ZStack {
            RadialGradient(colors: [accentColor.opacity(0.55), .clear], center: .center, startRadius: 10, endRadius: 190)
                .opacity(glowOpacity)

            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .fill(accentColor.opacity(0.75))
                    .frame(width: 4, height: 200 * rayProgress)
                    .offset(y: -100 * rayProgress)
                    .rotationEffect(.degrees(Double(index) / 18 * 360))
                    .opacity(rayOpacity)
            }

            RevealRing(diameter: 250, color: accentColor, lineWidth: 3,
                       opacity: ringOpacity, rotation: ringRotation, dashCount: 34)

            Circle()
                .stroke(accentColor.opacity(shockRingOpacity), lineWidth: 6)
                .frame(width: 280, height: 280)
                .scaleEffect(shockRingScale)
        }
        .frame(width: 320, height: 320)
        .allowsHitTesting(false)
    }

    // MARK: - Left: portrait + headline

    private var portraitColumn: some View {
        VStack(spacing: 14) {
            Text(isUltimate ? "SECRET UNLOCKED" : "BOND SEALED")
                .font(.caption.weight(.bold))
                .tracking(2.5)
                .foregroundStyle(accentColor)
                .opacity(infoStage >= 1 ? 1 : 0)
                .offset(y: infoStage >= 1 ? 0 : 8)

            ZStack {
                if hasArt {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 168, height: 168)
                        .clipShape(Circle())
                } else {
                    Circle().fill(accentColor.gradient).frame(width: 168, height: 168)
                    Image(systemName: definition.symbol)
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .overlay(Circle().strokeBorder(accentColor, lineWidth: 4))
            .shadow(color: accentColor.opacity(0.8), radius: 36)
            .scaleEffect(portraitScale)
            .opacity(portraitOpacity)
            .background(portraitFX)

            Text(isUltimate ? "A Different Kind of Olf..." : "Olf Has Joined You!")
                .font(.title2.weight(.heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(infoStage >= 1 ? 1 : 0)
                .offset(y: infoStage >= 1 ? 0 : 10)

            if !isUltimate, let element {
                HStack(spacing: 6) {
                    Image(systemName: element.symbol)
                    Text(LocalizedStringKey(element.displayName))
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(accentColor.opacity(0.25))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(accentColor.opacity(0.6), lineWidth: 1))
                .opacity(infoStage >= 2 ? 1 : 0)
                .offset(y: infoStage >= 2 ? 0 : 8)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.4), value: infoStage)
    }

    // MARK: - Right: who this Olf actually is

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    RevealAbilityRow(
                        icon: "sparkles", tint: Theme.gold, category: "Ultimate",
                        name: definition.ultimate.name, description: definition.ultimate.description
                    )
                    RevealAbilityRow(
                        icon: "bolt.fill", tint: Theme.softBlue, category: "Active Skill",
                        name: definition.activeSkill.name, description: definition.activeSkill.description
                    )
                    RevealAbilityRow(
                        icon: "shield.lefthalf.filled", tint: .white.opacity(0.75), category: "Passive",
                        name: definition.passive.name, description: definition.passive.description
                    )
                }
            }
            .opacity(infoStage >= 3 ? 1 : 0)
            .offset(y: infoStage >= 3 ? 0 : 14)

            Text(definition.flavorText)
                .font(.footnote.italic())
                .foregroundStyle(.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(infoStage >= 3 ? 1 : 0)

            Spacer(minLength: 0)

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .opacity(infoStage >= 4 ? 1 : 0)
            .offset(y: infoStage >= 4 ? 0 : 10)

            Text("Tap anywhere to continue")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(infoStage >= 4 ? 1 : 0)
        }
        .frame(maxWidth: 380)
        .animation(.easeOut(duration: 0.4), value: infoStage)
    }

    // MARK: - Opening sequence

    private func runSequence() {
        withAnimation(.easeOut(duration: 0.1)) { flashOpacity = isUltimate ? 0.75 : 0.55 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.45)) { flashOpacity = 0 }
        }
        shockRingOpacity = 0.9
        withAnimation(.easeOut(duration: 0.7)) {
            shockRingScale = isUltimate ? 3.2 : 2.6
            shockRingOpacity = 0
        }

        withAnimation(.interpolatingSpring(stiffness: 190, damping: 14)) {
            portraitScale = 1
            portraitOpacity = 1
            glowOpacity = 1
            ringOpacity = 1
        }
        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        rayOpacity = 1
        withAnimation(.easeOut(duration: 0.55)) { rayProgress = 1 }

        for (index, delay) in [0.22, 0.4, 0.62, 0.85].enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                infoStage = index + 1
            }
        }
    }
}

private struct RevealAbilityRow: View {
    let icon: String
    let tint: Color
    let category: String
    let name: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 22)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey(category))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(tint)
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Press feedback for the element tiles: scales down while held (matching
/// `PrimaryButtonStyle`'s convention elsewhere in the app) and reports the
/// pressed state up to the hero portrait so its glow can preview the
/// element before the tap is even released.
private struct GlowingTileButtonStyle: ButtonStyle {
    let element: Element
    @Binding var pressedElement: Element?

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                pressedElement = isPressed ? element : (pressedElement == element ? nil : pressedElement)
            }
    }
}

#Preview {
    StarterOlfChoiceView(onChoose: { _ in })
}
