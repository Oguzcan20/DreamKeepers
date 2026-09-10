import SwiftUI

/// Full reference page for one Dreamkeeper — art, stats, every ability with
/// what it actually does in battle, its element matchups, and its lore.
/// Presented as an in-place overlay by `DreamkeeperCodexView` rather than a
/// `.sheet`, matching the rest of this landscape-locked app: a genuine modal
/// presentation has repeatedly left other screens' safe-area layout
/// corrupted after dismissal (see `SummoningShrineView`'s equivalent note).
struct DreamkeeperCodexDetailView: View {
    let definition: DreamkeeperDefinition
    let isOwned: Bool
    let ownedCount: Int
    let maxStars: Int
    /// Only needed to read the currently-deployed team, for the Zwillingsbund
    /// active/inactive indicator on Igo/Ames — see `TwinBond`.
    let gameState: GameState
    var onClose: () -> Void

    @State private var appeared = false

    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }
    /// The real visible content region (screen bounds minus safe-area
    /// insets). Force-fitting to raw `UIScreen.main.bounds` here — which
    /// includes the notch / Dynamic Island and home-indicator strips — made
    /// this overlay taller than its slot, so SwiftUI centred it and clipped
    /// the close button off the top edge. `dk_safeContentSize` keeps the
    /// "don't trust the proposed size" behaviour while staying on-screen.
    private var screenSize: CGSize { UIScreen.dk_safeContentSize }

    /// Reference ranges pulled from the whole catalog so every stat bar reads
    /// relative to the strongest Dreamkeeper in the game, not some arbitrary
    /// fixed scale — a bar at 100% actually means "the tankiest HP in the
    /// game," for example.
    private static let allDefinitions = DreamkeeperCatalog.starter.definitions
    private static let maxHP = allDefinitions.map(\.baseStats.hp).max() ?? 1
    private static let maxAttack = allDefinitions.map(\.baseStats.attack).max() ?? 1
    private static let maxDefense = allDefinitions.map(\.baseStats.defense).max() ?? 1
    private static let maxSpeed = allDefinitions.map(\.baseStats.speed).max() ?? 1

    /// What each role's Ultimate/Active Skill actually resolves to in
    /// `BattleEngine` — the numbers on a skill card don't explain themselves
    /// without this.
    private static let roleMechanics: [Role: String] = [
        .tank: "High HP and Defense — built to endure. Both the Ultimate and Active Skill strike the enemy directly.",
        .damage: "High Attack. Both the Ultimate and Active Skill strike the enemy for extra damage.",
        .healer: "The Ultimate heals the whole team at once; the Active Skill heals whichever ally is lowest on HP.",
        .support: "The Ultimate boosts the whole team's Attack for the rest of the battle; the Active Skill boosts its own Attack.",
        .control: "The Ultimate strikes the enemy and briefly stuns it; the Active Skill is a quick strike.",
        .guardian: "The Ultimate shields the whole team; the Active Skill strikes the enemy and slows it."
    ]

    private var strongAgainst: [Element] {
        Element.allCases.filter { definition.element.multiplier(against: $0) > 1.0 }
    }

    private var weakAgainst: [Element] {
        Element.allCases.filter { $0.multiplier(against: definition.element) > 1.0 }
    }

    /// `AbilityRow.detail` and `statBonusSummary` build plain `String`s from
    /// interpolated numbers, so `Text` always renders them verbatim in
    /// whichever language they were written in — they never go through
    /// `Localizable.xcstrings` no matter how the pieces are wrapped, the same
    /// gap `GameState.notificationText` exists to close for local
    /// notifications. Picking the finished sentence directly, in whichever
    /// language is active, is the only way these read correctly in German.
    private var isGerman: Bool {
        gameState.preferredLocale.language.languageCode?.identifier == "de"
    }

    private func localized(en: String, de: String) -> String {
        isGerman ? de : en
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            RadialGradient(
                colors: [definition.element.color.opacity(0.3), .clear],
                center: .center, startRadius: 10, endRadius: 460
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                closeHeader

                ScrollView {
                    HStack(alignment: .top, spacing: 20) {
                        heroColumn
                            .frame(width: 250)

                        VStack(spacing: 14) {
                            roleCard
                            statsCard
                            abilitiesCard
                            matchupCard
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.97)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.height > 90 && abs(value.translation.width) < value.translation.height {
                        onClose()
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var closeHeader: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Hero column

    private var heroColumn: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(definition.rarity.gradient)
                    .frame(width: 132, height: 132)
                    .blur(radius: 26)
                    .opacity(0.55)

                if hasArt {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 132, height: 132)
                        .clipShape(Circle())
                } else {
                    Circle().fill(definition.rarity.gradient).frame(width: 132, height: 132)
                    Image(systemName: definition.symbol)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(.white)
                }

                Circle()
                    .strokeBorder(definition.rarity.gradient, lineWidth: 3)
                    .frame(width: 132, height: 132)
            }
            .shadow(color: definition.element.color.opacity(0.5), radius: 18)

            Text(definition.name)
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                PillBadge(icon: definition.element.symbol, text: definition.element.displayName, tint: definition.element.color)
                PillBadge(icon: definition.role.symbol, text: definition.role.displayName, tint: .white.opacity(0.7))
            }
            PillBadge(icon: "sparkles", text: definition.rarity.displayName, tint: definition.rarity.primaryColor, filled: true)

            ownershipCard
            storyCard
        }
    }

    private var ownershipCard: some View {
        GlassCard {
            if isOwned {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.gold)
                        Text("In Your Collection")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Text("Owned ×\(ownedCount)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                    StarRow(stars: maxStars)
                }
            } else {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "questionmark.circle.fill").foregroundStyle(.white.opacity(0.5))
                        Text("Not Owned Yet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text("Find this Dreamkeeper at the Summoning Shrine.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var storyCard: some View {
        GlassCard {
            VStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(definition.element.color.opacity(0.7))
                Text(LocalizedStringKey(definition.flavorText))
                    .font(.caption.italic())
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Right column

    private var roleCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: definition.role.symbol)
                    .foregroundStyle(Theme.softBlue)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    Text("How It Fights")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(Self.roleMechanics[definition.role] ?? ""))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var statsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Base Stats")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                StatBar(label: "HP", value: definition.baseStats.hp, maxValue: Self.maxHP, tint: .red.opacity(0.75))
                StatBar(label: "ATK", value: definition.baseStats.attack, maxValue: Self.maxAttack, tint: Theme.gold)
                StatBar(label: "DEF", value: definition.baseStats.defense, maxValue: Self.maxDefense, tint: Theme.softBlue)
                StatBar(label: "SPD", value: definition.baseStats.speed, maxValue: Self.maxSpeed, tint: Theme.violet)
            }
        }
    }

    private var abilitiesCard: some View {
        VStack(spacing: 10) {
            AbilityRow(
                icon: "sparkles", tint: Theme.gold, category: "Ultimate",
                name: definition.ultimate.name, description: definition.ultimate.description,
                detail: localized(
                    en: "Charges after \(definition.ultimate.attacksToCharge) attacks · ×\(String(format: "%.1f", definition.ultimate.damageMultiplier)) power",
                    de: "Lädt nach \(definition.ultimate.attacksToCharge) Angriffen · ×\(String(format: "%.1f", definition.ultimate.damageMultiplier)) Stärke"
                )
            )
            AbilityRow(
                icon: "bolt.fill", tint: Theme.softBlue, category: "Active Skill",
                name: definition.activeSkill.name, description: definition.activeSkill.description,
                detail: localized(
                    en: "\(Int(definition.activeSkill.cooldownSeconds))s cooldown · ×\(String(format: "%.1f", definition.activeSkill.effectMultiplier)) power",
                    de: "\(Int(definition.activeSkill.cooldownSeconds)) s Abklingzeit · ×\(String(format: "%.1f", definition.activeSkill.effectMultiplier)) Stärke"
                )
            )
            AbilityRow(
                icon: "shield.lefthalf.filled", tint: .white.opacity(0.7), category: "Passive",
                name: definition.passive.name, description: definition.passive.description,
                detail: statBonusSummary(definition.passive.statBonus)
            )
            twinBondRow
        }
    }

    /// Igo/Ames only — the visible hint for `TwinBond`, gold and "Aktiv" while
    /// both are in the deployed formation, gray and "Inaktiv" otherwise.
    @ViewBuilder
    private var twinBondRow: some View {
        if TwinBond.isBondCharacter(definition.id) {
            let active = TwinBond.isActive(memberDefinitionIDs: gameState.deployedTeam.map(\.definitionID))
            AbilityRow(
                icon: "link", tint: active ? Theme.gold : .white.opacity(0.4),
                category: localized(en: "Twin Bond", de: "Zwillingsbund"),
                name: "+75% ATK/DEF",
                description: localized(
                    en: definition.id == TwinBond.igoID
                        ? "Twin Bond: +75% ATK/DEF — only active while Ames is also in the battle formation."
                        : "Twin Bond: +75% ATK/DEF — only active while Igo is also in the battle formation.",
                    de: definition.id == TwinBond.igoID
                        ? "Zwillingsbund: +75% ATK/DEF — nur aktiv, wenn Ames ebenfalls in der Kampfformation steht."
                        : "Zwillingsbund: +75% ATK/DEF — nur aktiv, wenn Igo ebenfalls in der Kampfformation steht."
                ),
                detail: localized(en: active ? "Active" : "Inactive", de: active ? "Aktiv" : "Inaktiv")
            )
        }
    }

    private func statBonusSummary(_ bonus: Stats) -> String {
        var parts: [String] = []
        if bonus.hp > 0 { parts.append("+\(Int(bonus.hp)) HP") }
        if bonus.attack > 0 { parts.append("+\(Int(bonus.attack)) ATK") }
        if bonus.defense > 0 { parts.append("+\(Int(bonus.defense)) DEF") }
        if bonus.speed > 0 { parts.append("+\(Int(bonus.speed)) SPD") }
        return parts.isEmpty ? localized(en: "Always active", de: "Immer aktiv") : parts.joined(separator: " · ")
    }

    private var matchupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Element Matchups")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                if strongAgainst.isEmpty && weakAgainst.isEmpty {
                    Text("Balanced against every element — no bonus or penalty either way.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    if !strongAgainst.isEmpty {
                        MatchupRow(icon: "arrow.up.circle.fill", tint: .green, label: "Strong Against", elements: strongAgainst)
                    }
                    if !weakAgainst.isEmpty {
                        MatchupRow(icon: "arrow.down.circle.fill", tint: .red.opacity(0.85), label: "Weak Against", elements: weakAgainst)
                    }
                }
            }
        }
    }
}

private struct PillBadge: View {
    var icon: String
    var text: String
    var tint: Color
    var filled: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(LocalizedStringKey(text)).font(.caption2.weight(.semibold))
        }
        .foregroundStyle(filled ? .black : .white.opacity(0.9))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(filled ? AnyShapeStyle(tint) : AnyShapeStyle(tint.opacity(0.25)))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(tint.opacity(filled ? 0 : 0.5), lineWidth: 1))
    }
}

private struct StatBar: View {
    let label: String
    let value: Double
    let maxValue: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                Text("\(Int(value))")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(tint)
                        .frame(width: max(4, geo.size.width * CGFloat(min(value / maxValue, 1))))
                }
            }
            .frame(height: 7)
        }
    }
}

private struct AbilityRow: View {
    let icon: String
    let tint: Color
    let category: String
    let name: String
    let description: String
    let detail: String

    var body: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(LocalizedStringKey(category))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(tint)
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                    Text(LocalizedStringKey(description))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(detail)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer(minLength: 0)
            }
        }
    }
}

private struct MatchupRow: View {
    let icon: String
    let tint: Color
    let label: String
    let elements: [Element]

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(LocalizedStringKey(label))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.8))
            ForEach(elements) { element in
                HStack(spacing: 3) {
                    Image(systemName: element.symbol).font(.caption2)
                    Text(LocalizedStringKey(element.displayName)).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(element.color.opacity(0.3))
                .clipShape(Capsule())
            }
            Spacer(minLength: 0)
        }
    }
}
