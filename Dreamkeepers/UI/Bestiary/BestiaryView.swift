import SwiftUI

/// Dream Observatory (spec: "Schaltet neue Inhalte frei" — unlocks new
/// content). Every monster and boss fought gets logged here; undiscovered
/// entries stay silhouetted until the player meets them in battle.
struct BestiaryView: View {
    var gameState: GameState
    var navigate: (AppRoute) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(WorldCatalog.worlds) { world in
                        WorldCodexSection(world: world, gameState: gameState)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
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
            VStack(spacing: 2) {
                Text("Dream Observatory")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(gameState.bestiaryDiscoveredCount)/\(gameState.bestiaryTotalCount) Discovered")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Color.clear.frame(width: 40, height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

private struct WorldCodexSection: View {
    let world: World
    var gameState: GameState

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(world.name))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(LocalizedStringKey(world.description))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(MonsterCatalog.allEntries(forWorld: world.id), id: \.name) { entry in
                        CodexEntryCard(
                            name: entry.name, symbol: entry.symbol, lore: entry.lore,
                            isBoss: entry.isBoss, accent: world.accentColor,
                            isDiscovered: gameState.isDiscovered(entry.name)
                        )
                    }
                }
            }
        }
    }
}

private struct CodexEntryCard: View {
    let name: String
    let symbol: String
    let lore: String
    let isBoss: Bool
    let accent: Color
    let isDiscovered: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MonsterBadge(name: name, symbol: symbol, isBoss: isBoss, accent: accent, isDiscovered: isDiscovered)

            Text(isDiscovered ? name : "???")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Text(LocalizedStringKey(isDiscovered ? lore : "Not yet encountered."))
                .font(.caption2)
                .foregroundStyle(.white.opacity(isDiscovered ? 0.6 : 0.35))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isBoss && isDiscovered ? Color.red.opacity(0.4) : Theme.cardStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// A layered fantasy-badge treatment (glow + gradient medallion + bevel ring)
/// standing in for real per-monster art where none exists yet — still just
/// an SF Symbol underneath, but staged like an inventory icon rather than a
/// flat tinted circle. Once a `Monster_<Name>` asset is supplied, that art
/// is used instead (see `MonsterArt`), same glow/bevel frame around it.
struct MonsterBadge: View {
    var name: String
    var symbol: String
    var isBoss: Bool
    var accent: Color
    var isDiscovered: Bool
    var size: CGFloat = 44

    private var tint: Color { isBoss ? .red : accent }
    private var hasArt: Bool { isDiscovered && MonsterArt.hasArt(for: name) }

    var body: some View {
        ZStack {
            if hasArt {
                Image(MonsterArt.assetName(for: name))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(
                        isDiscovered
                            ? LinearGradient(colors: [tint.opacity(0.85), tint.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: size, height: size)

                Image(systemName: isDiscovered ? symbol : "questionmark")
                    .font(.system(size: size * 0.4, weight: .semibold))
                    .foregroundStyle(isDiscovered ? .white : .white.opacity(0.3))
                    .shadow(color: .black.opacity(isDiscovered ? 0.35 : 0), radius: 2, y: 1)
            }

            Circle()
                .strokeBorder(
                    isDiscovered
                        ? LinearGradient(colors: [(isBoss ? Theme.gold : .white).opacity(0.85), tint.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.18)], startPoint: .top, endPoint: .bottom),
                    lineWidth: isBoss && isDiscovered ? 1.6 : 1
                )
                .frame(width: size, height: size)
                .shadow(color: isDiscovered ? tint.opacity(0.4) : .clear, radius: 6, y: 2)

            if isBoss && isDiscovered {
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .offset(x: size * 0.34, y: -size * 0.34)
            }
        }
        .frame(width: size, height: size)
    }
}
