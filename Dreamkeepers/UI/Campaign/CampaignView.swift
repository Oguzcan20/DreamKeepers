import SwiftUI

struct CampaignView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    @State private var appeared = false
    @State private var sweepResult: BattleResultSummary?
    @State private var sweepDismissWorkItem: DispatchWorkItem?
    /// Non-nil while the "Fight or Sweep?" prompt is up for an already-
    /// cleared stage — tapping such a stage no longer jumps straight into
    /// a replay or requires a long-press to find the sweep option.
    @State private var pendingChoiceStage: Int?
    @State private var showInsufficientEnergyAlert = false
    /// Which stage triggered the insufficient-Energy alert — needed so the
    /// alert can quote the right cost (boss stages cost more).
    @State private var insufficientEnergyStage = 0

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.violet, bottomTint: Theme.softBlue)

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(Array(WorldCatalog.worlds.enumerated()), id: \.element.id) { index, world in
                            WorldSection(world: world, gameState: gameState, onTapStage: tapStage)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 16)
                                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: appeared)
                        }

                        if gameState.isCampaignComplete {
                            GlassCard {
                                Text("You've cleared every known dream. More worlds are on the way.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }

            VStack {
                if let sweepResult {
                    SweepToast(result: sweepResult)
                        .padding(.top, 74)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        // Cleared stages offer a real choice instead of a hidden long-press —
        // both options cost the same Energy for a given stage (see
        // `EnergySystem.stageCost(isBoss:)`), so this is purely "watch it
        // happen" vs. "skip straight to the payout".
        .confirmationDialog(
            "Stage \(pendingChoiceStage ?? 0) — already cleared",
            isPresented: Binding(
                get: { pendingChoiceStage != nil },
                set: { if !$0 { pendingChoiceStage = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let stage = pendingChoiceStage {
                let cost = EnergySystem.stageCost(isBoss: stage % World.stagesPerWorld == 0)
                Button("Fight (\(cost) Energy)") {
                    pendingChoiceStage = nil
                    fight(stage)
                }
                Button("Sweep — Instant Clear (\(cost) Energy)") {
                    pendingChoiceStage = nil
                    sweep(stage)
                }
                Button("Cancel", role: .cancel) { pendingChoiceStage = nil }
            }
        } message: {
            Text("Replay the battle for the same rewards, or skip straight to the payout.")
        }
        .alert("Not Enough Energy", isPresented: $showInsufficientEnergyAlert) {
            if gameState.canRefillEnergyWithGems {
                Button("Refill for \(gameState.nextEnergyRefillGemCost) Gems") {
                    gameState.refillEnergyWithGems()
                    gameState.playHaptic(.light)
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            let cost = EnergySystem.stageCost(isBoss: insufficientEnergyStage % World.stagesPerWorld == 0)
            Text("This stage costs \(cost) Energy. You have \(gameState.energy)/\(gameState.maxEnergy).")
        }
    }

    /// Cleared, sweepable stages ask which path to take; everything else
    /// (the frontier stage, a stage still selected mid-attempt) fights
    /// directly, same as before.
    private func tapStage(_ stage: Int) {
        gameState.playHaptic(.light)
        if gameState.canSweepStage(stage) {
            pendingChoiceStage = stage
        } else {
            fight(stage)
        }
    }

    /// Spends Energy and opens the Battle screen. Shows the insufficient-
    /// Energy alert instead when the player can't afford the attempt.
    private func fight(_ stage: Int) {
        guard gameState.attemptStage(stage) else {
            insufficientEnergyStage = stage
            showInsufficientEnergyAlert = true
            return
        }
        navigate(.battle)
    }

    /// Instantly clears an already-cleared stage via `GameState.sweepStage`
    /// and flashes the payout as a brief toast instead of a full result
    /// screen — a sweep is deliberately lighter-weight than a played battle.
    private func sweep(_ stage: Int) {
        guard let result = gameState.sweepStage(stage) else {
            insufficientEnergyStage = stage
            showInsufficientEnergyAlert = true
            return
        }
        gameState.playHaptic(.success)
        sweepDismissWorkItem?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            sweepResult = result
        }
        let workItem = DispatchWorkItem {
            withAnimation(.easeIn(duration: 0.3)) { sweepResult = nil }
        }
        sweepDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: workItem)
    }

    /// Blurred so the concept art's own baked-in map labels/UI read as
    /// abstract texture instead of competing with the real header controls
    /// drawn on top — same trick as `BattleView.battleBanner`. Gives
    /// Campaign the same cinematic depth as the Main Menu key art instead
    /// of a flat gradient bar.
    private var header: some View {
        Image("CampaignBanner")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 64)
            .frame(maxWidth: .infinity)
            .clipped()
            .blur(radius: 5)
            .overlay(
                LinearGradient(
                    colors: [Theme.deepNavy.opacity(0.3), Theme.deepNavy.opacity(0.85)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, .white.opacity(0.14), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 1)
            }
            .overlay {
                HStack {
                    Button {
                        navigate(.dreamHaven)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back")
                    Spacer()
                    Text("Campaign")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Spacer()
                    energyPill
                }
                .padding(.horizontal, 20)
            }
            .ignoresSafeArea(edges: .top)
    }

    /// Same Energy readout as the Dream Haven header, mirrored here so the
    /// player can see at a glance whether they can afford the next stage
    /// without backing out of Campaign.
    private var energyPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill")
            Text("\(gameState.energy)/\(gameState.maxEnergy)")
        }
        .font(.caption.weight(.semibold).monospacedDigit())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityLabel("Energy \(gameState.energy) of \(gameState.maxEnergy)")
    }
}

private struct WorldSection: View {
    let world: World
    var gameState: GameState
    var onTapStage: (Int) -> Void

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(world.name))
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(LocalizedStringKey(world.description))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: world.elementBias.first?.symbol ?? "sparkles")
                        .font(.title3)
                        .foregroundStyle(world.accentColor)
                        .padding(8)
                        .background(world.accentColor.opacity(0.15))
                        .clipShape(Circle())
                }

                HStack(spacing: 10) {
                    ForEach(world.stages, id: \.self) { stage in
                        StageNode(
                            stage: stage,
                            isBoss: stage == world.lastStage,
                            accent: world.accentColor,
                            state: state(for: stage),
                            isSweepable: gameState.canSweepStage(stage)
                        ) {
                            onTapStage(stage)
                        }
                    }
                }
            }
        }
        // Same accented-card language as the Shop's starter/VIP cards
        // (tinted glow + matching stroke), keyed to each world's own accent
        // so the map reads as ten distinct places rather than ten identical
        // cards with different text.
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [world.accentColor.opacity(0.22), .clear],
                        center: .topTrailing, startRadius: 4, endRadius: 240
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(world.accentColor.opacity(0.4), lineWidth: 1.25)
        )
        .shadow(color: world.accentColor.opacity(0.2), radius: 10, y: 3)
    }

    private func state(for stage: Int) -> StageNode.State {
        if !gameState.isStageUnlocked(stage) { return .locked }
        if stage == gameState.selectedStage { return .selected }
        if stage < gameState.currentStage { return .cleared }
        return .frontier
    }
}

private struct StageNode: View {
    enum State { case locked, cleared, frontier, selected }

    let stage: Int
    let isBoss: Bool
    let accent: Color
    let state: State
    /// True only for an already-cleared stage — shows the small bolt badge
    /// hinting that tapping it now offers a Sweep option, not just a replay.
    var isSweepable: Bool = false
    var onTap: () -> Void

    // `@SwiftUI.State`, not `@State` — this type also declares a nested
    // `State` enum for the node's own status, which would otherwise shadow
    // SwiftUI's property wrapper of the same name.
    @SwiftUI.State private var pulse = false

    /// The stage the player would actually tackle next — glows softly so
    /// the map reads at a glance instead of requiring the player to scan
    /// checkmarks and numbers.
    private var isActionable: Bool { state == .frontier || state == .selected }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isActionable {
                    Circle()
                        .fill((isBoss ? Color.red : accent).opacity(0.5))
                        .frame(width: 44, height: 44)
                        .blur(radius: 8)
                        .scaleEffect(pulse ? 1.35 : 1)
                        .opacity(pulse ? 0.85 : 0.45)
                }

                Circle()
                    .fill(fillColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle().stroke(state == .selected ? Theme.gold : .clear, lineWidth: 2)
                    )
                    .overlay(
                        Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

                if state == .locked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                } else if isBoss {
                    Image(systemName: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                } else if state == .cleared {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(stage)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .disabled(state == .locked)
        .opacity(state == .locked ? 0.5 : 1)
        .overlay(alignment: .bottomTrailing) {
            // Small always-visible hint that tapping this cleared stage now
            // offers a Sweep option alongside a normal replay.
            if isSweepable {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(3)
                    .background(Theme.gold)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.deepNavy.opacity(0.6), lineWidth: 1))
                    .offset(x: 2, y: 2)
                    .allowsHitTesting(false)
            }
        }
        // `Button` already gives VoiceOver the tap affordance, but with no
        // label it just reads the glyph inside ("lock", "checkmark", or a
        // bare number) — not enough to tell stages apart. Speak the stage
        // number, boss status and progress state explicitly instead.
        .accessibilityLabel(
            (isBoss ? "Boss Stage \(stage)" : "Stage \(stage)")
            + (state == .locked ? ", locked" : state == .cleared ? ", cleared" : "")
        )
        .onAppear {
            if isActionable {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private var fillColor: Color {
        switch state {
        case .locked: return Color.white.opacity(0.06)
        case .cleared: return accent.opacity(0.55)
        case .frontier, .selected: return isBoss ? Color.red.opacity(0.7) : accent
        }
    }
}

/// Brief, self-dismissing payout summary for a swept stage — lighter than
/// `BattleView`'s full `OutcomeOverlay` since sweeping is meant to be the
/// fast path, not another screen to sit through.
private struct SweepToast: View {
    let result: BattleResultSummary

    var body: some View {
        GlassCard {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stage \(result.stage) swept")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("+\(result.goldGained) Gold · +\(result.expGained) EXP")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 4)
        }
        .fixedSize()
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }
}
