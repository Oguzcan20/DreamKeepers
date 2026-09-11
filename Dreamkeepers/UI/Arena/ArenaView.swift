import SwiftUI

/// Arena Tower hub: a scrollable list of all 100 floors, always fully
/// visible (spec: "ALLE 100 stufen sollen zu sehen sein") — a player farming
/// gear can jump straight to whichever cleared floor drops what they need,
/// not just the current frontier. Floors `1...arenaFloor` are unlocked;
/// `arenaFloor` itself is the still-unclaimed first-clear frontier, and
/// every floor below it is already cleared and freely replayable for its
/// smaller standard reward. There's no real backend or matchmaking (see
/// `LeaderboardService`) — every floor's rival is a freshly-synthesized,
/// deterministic stand-in from `ArenaSystem`, not another real player's team.
struct ArenaView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void
    var onFight: (Int) -> Void

    @State private var appeared = false
    @State private var showNoTicketsAlert = false
    @State private var showNoTeamAlert = false
    @State private var showRebirth = false

    var body: some View {
        ZStack {
            AmbientBackground(topTint: Theme.gold, bottomTint: Theme.violet)

            VStack(spacing: 0) {
                header
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                progressCard
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                    .opacity(appeared ? 1 : 0)

                rebirthCard
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)

                if gameState.isArenaTowerCleared {
                    towerClearedBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .opacity(appeared ? 1 : 0)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            // Diamond (top, hardest) down to Bronze (bottom,
                            // floor 1) — floors already list highest-first, so
                            // grouping by tier in the same order reads as
                            // physically climbing the tower from its base.
                            ForEach(ArenaTier.allCases.reversed(), id: \.self) { tier in
                                TowerZoneBanner(tier: tier)
                                ForEach(tier.floorRange.reversed(), id: \.self) { floor in
                                    ArenaFloorRow(floor: floor, gameState: gameState, onFight: attemptFight)
                                        .id(floor)
                                }
                            }
                        }
                        // A single vertical line behind the whole climb,
                        // positioned through the floor rows' icon column (16pt
                        // GlassCard inset + 23pt to the 46pt icon's center) —
                        // hidden behind each opaque card, it only shows in the
                        // gaps between platforms, reading as a rope/ladder
                        // strung down the tower rather than a plain list.
                        .background(alignment: .leading) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.gold.opacity(0.55), Theme.violet.opacity(0.55)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(width: 3)
                                .padding(.leading, 37.5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .opacity(appeared ? 1 : 0)
                    .onAppear {
                        // Land on the current climb frontier instead of the
                        // scroll view's natural top (floor 100) — that's
                        // where a returning player almost always wants to be.
                        let target = min(gameState.arenaFloor, ArenaSystem.maxFloor)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            proxy.scrollTo(target, anchor: .center)
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
        .alert("No Trial Tickets Left", isPresented: $showNoTicketsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've used all your Endless Trial attempts for today. Come back tomorrow!")
        }
        .alert("No team deployed", isPresented: $showNoTeamAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Deploy a team before entering the Endless Trial.")
        }
        .sheet(isPresented: $showRebirth) {
            RebirthSheet(gameState: gameState)
        }
    }

    private func attemptFight(_ floor: Int) {
        guard !gameState.deployedTeam.isEmpty else {
            showNoTeamAlert = true
            return
        }
        guard gameState.canAffordArenaBattle() else {
            showNoTicketsAlert = true
            return
        }
        onFight(floor)
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
            Text("The Endless Trial")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var progressCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.25)).frame(width: 48, height: 48)
                    Image(systemName: gameState.arenaTier.symbol)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(gameState.arenaTier.displayName))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Floor \(min(gameState.arenaFloor, gameState.arenaMaxFloor))/\(gameState.arenaMaxFloor)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "ticket.fill")
                            .font(.caption)
                            .foregroundStyle(Theme.softBlue)
                        Text("\(gameState.arenaTicketsRemainingToday)/\(ArenaSystem.maxTicketsPerDay)")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    if gameState.arenaBonusTickets > 0 {
                        Text("+\(gameState.arenaBonusTickets) bonus")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Theme.softBlue.opacity(0.85))
                    }
                }
            }
        }
    }

    /// Compact entry point into `RebirthSheet` — glows gold once floor 50 is
    /// reached so a player scanning the hub notices rebirth became available.
    private var rebirthCard: some View {
        Button {
            showRebirth = true
        } label: {
            GlassCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.violet.opacity(0.3)).frame(width: 40, height: 40)
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.violet)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rebirth")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(gameState.soulPoints) Soul Points")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(gameState.canRebirth ? Theme.gold.opacity(0.55) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var towerClearedBanner: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.gold.opacity(0.35)).frame(width: 44, height: 44)
                        .shadow(color: Theme.gold.opacity(0.6), radius: 10)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tower Cleared!")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.gold)
                    Text("Every floor stays open below for farming gear.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Theme.gold.opacity(0.6), lineWidth: 1.5)
        )
    }
}

/// Section header shown once per `ArenaTier`, between that tier's block of
/// floor rows — the visual "floor" of the actual tower structure (real
/// backdrop art if it exists, a tier-tinted gradient otherwise), so climbing
/// the list reads as ascending through distinct zones of one building
/// instead of scrolling a flat, undifferentiated list. See
/// `Legal/Missing_Art_Prompts.pdf` for `ArenaTower_<Tier>` generation prompts.
private struct TowerZoneBanner: View {
    let tier: ArenaTier

    private var hasArt: Bool { ArenaArt.hasArt(for: tier) }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if hasArt {
                Image(ArenaArt.assetName(for: tier))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 96)
                    .clipped()
                    .overlay(
                        LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .center)
                    )
            } else {
                tierGradient.frame(height: 96)
            }

            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(.black.opacity(0.35)).frame(width: 38, height: 38)
                    Image(systemName: tier.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(tier.zoneName)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3)
                    Text("Floors \(tier.floorRange.lowerBound)–\(tier.floorRange.upperBound)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(12)
        }
        .frame(height: 96)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    private var tierGradient: LinearGradient {
        switch tier {
        case .bronze:
            return LinearGradient(colors: [Color(red: 0.55, green: 0.35, blue: 0.18), Color(red: 0.3, green: 0.19, blue: 0.1)], startPoint: .top, endPoint: .bottom)
        case .silver:
            return LinearGradient(colors: [Color(red: 0.72, green: 0.74, blue: 0.78), Color(red: 0.4, green: 0.42, blue: 0.46)], startPoint: .top, endPoint: .bottom)
        case .gold:
            return LinearGradient(colors: [Theme.gold, Color(red: 0.5, green: 0.36, blue: 0.08)], startPoint: .top, endPoint: .bottom)
        case .platinum:
            return LinearGradient(colors: [Color(red: 0.68, green: 0.88, blue: 0.92), Color(red: 0.28, green: 0.48, blue: 0.53)], startPoint: .top, endPoint: .bottom)
        case .diamond:
            return LinearGradient(colors: [Theme.softBlue, Theme.violet], startPoint: .top, endPoint: .bottom)
        }
    }
}

/// One floor's row in the Tower list. Shows the exact first-clear reward
/// (deterministic — see `ArenaSystem.firstClearEquipment`) for a floor not
/// yet cleared, or the smaller repeatable standard reward for one that's
/// already been beaten, so a player can scan the whole list for the gear
/// they're after before spending a ticket.
private struct ArenaFloorRow: View {
    let floor: Int
    var gameState: GameState
    var onFight: (Int) -> Void

    private var isUnlocked: Bool { gameState.isFloorUnlocked(floor) }
    private var isCleared: Bool { gameState.isFloorCleared(floor) }
    private var isFrontier: Bool { floor == gameState.arenaFloor }
    private var isMilestone: Bool { ArenaSystem.isMilestoneFloor(floor) }
    private var opponent: ArenaOpponent { gameState.arenaOpponent(forFloor: floor) }
    private var definition: DreamkeeperDefinition? { gameState.catalog.definition(for: opponent.definitionID) }
    private var firstClearRarity: Rarity { ArenaSystem.firstClearRarity(forFloor: floor) }

    var body: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isUnlocked ? ((definition?.rarity.gradient).map { AnyShapeStyle($0) } ?? AnyShapeStyle(Theme.violet.opacity(0.35))) : AnyShapeStyle(Color.white.opacity(0.06)))
                        .frame(width: 46, height: 46)
                    if isUnlocked, let definition {
                        Image(systemName: definition.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    } else if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Floor \(floor)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isUnlocked ? .white : .white.opacity(0.4))
                        if isMilestone && !isCleared {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundStyle(Theme.gold)
                        }
                        if isCleared {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundStyle(.green.opacity(0.75))
                        }
                    }

                    if isUnlocked {
                        Text("Lv \(opponent.level) · \(opponent.name)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    rewardPreview
                }

                Spacer()

                Button {
                    onFight(floor)
                } label: {
                    Text(isCleared ? "Farm" : "Fight")
                }
                .buttonStyle(PrimaryButtonStyle(tint: isMilestone && !isCleared ? Theme.gold : Theme.violet))
                .disabled(!isUnlocked)
                .opacity(isUnlocked ? 1 : 0.35)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .stroke(isFrontier ? Theme.gold.opacity(0.55) : .clear, lineWidth: 1.5)
        )
        .opacity(isUnlocked ? 1 : 0.6)
    }

    @ViewBuilder
    private var rewardPreview: some View {
        HStack(spacing: 10) {
            if isCleared {
                Label("\(ArenaSystem.standardGoldReward(floor: floor))", systemImage: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                Label("Gear chance", systemImage: "shippingbox.fill")
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Label("\(ArenaSystem.firstClearGoldReward(floor: floor))", systemImage: "circle.hexagongrid.fill")
                    .foregroundStyle(Theme.gold)
                Label(LocalizedStringKey(firstClearRarity.displayName), systemImage: "shippingbox.fill")
                    .foregroundStyle(firstClearRarity.primaryColor)
            }
        }
        .font(.caption2.weight(.semibold))
    }
}
