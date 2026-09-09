import SwiftUI
import UIKit

/// Looks up hand-supplied monster/boss art in the asset catalog by name
/// (`Monster_<NameWithoutSpaces>`) so screens can show real artwork where
/// it exists and fall back to the icon-badge treatment everywhere else —
/// no per-monster wiring needed as more art is added over time.
enum MonsterArt {
    static func assetName(for name: String) -> String {
        "Monster_" + name.replacingOccurrences(of: " ", with: "")
    }

    static func hasArt(for name: String) -> Bool {
        UIImage(named: assetName(for: name)) != nil
    }
}

/// Same lookup as `MonsterArt`, for the 12 playable Dreamkeepers
/// (`Dreamkeeper_<NameWithoutSpaces>`).
enum DreamkeeperArt {
    static func assetName(for name: String) -> String {
        "Dreamkeeper_" + name.replacingOccurrences(of: " ", with: "")
    }

    static func hasArt(for name: String) -> Bool {
        UIImage(named: assetName(for: name)) != nil
    }
}

/// Same lookup as `MonsterArt`, for equipment items (`Item_<NameWithoutSpaces>`).
enum ItemArt {
    static func assetName(for name: String) -> String {
        "Item_" + name.replacingOccurrences(of: " ", with: "")
    }

    static func hasArt(for name: String) -> Bool {
        UIImage(named: assetName(for: name)) != nil
    }
}

/// Looks up the Arena Tower's per-tier backdrop art (`ArenaTower_<TierName>`,
/// e.g. `ArenaTower_Diamond`) — one wide banner illustration per `ArenaTier`,
/// shown behind that tier's zone banner in `ArenaView`. `hasArt` gates a
/// graceful gradient fallback (see `TowerZoneBanner.tierGradient`) so the
/// Arena screen looks intentional before this art exists, exactly like
/// `MonsterArt`/`DreamkeeperArt` already do for their own screens.
enum ArenaArt {
    static func assetName(for tier: ArenaTier) -> String {
        "ArenaTower_" + tier.displayName
    }

    static func hasArt(for tier: ArenaTier) -> Bool {
        UIImage(named: assetName(for: tier)) != nil
    }
}

enum Theme {
    static let deepNavy = Color(red: 0.05, green: 0.06, blue: 0.13)
    static let midnightPurple = Color(red: 0.13, green: 0.09, blue: 0.24)
    static let softBlue = Color(red: 0.45, green: 0.62, blue: 0.95)
    static let violet = Color(red: 0.55, green: 0.4, blue: 0.9)
    static let gold = Color(red: 0.96, green: 0.78, blue: 0.35)
    static let cream = Color(white: 0.96)

    static let background = LinearGradient(
        colors: [deepNavy, midnightPurple],
        startPoint: .top, endPoint: .bottom
    )

    static let cardBackground = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.12)

    static let cornerRadius: CGFloat = 18
}

/// Real frosted-glass material with a top sheen and a bevel rim (bright
/// top-left, dark bottom-right) plus a grounding drop shadow — the same
/// language as the Main Menu's CTA panel and play button, applied once here
/// so every card in the app shares it instead of the old flat tinted-fill
/// look.
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial)
            .background(Theme.cardBackground)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.09), .clear],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.32), Theme.cardStroke, .black.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.violet

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    LinearGradient(colors: [tint.opacity(1.1), tint.opacity(0.65)], startPoint: .top, endPoint: .bottom)
                    LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.75), .white.opacity(0.15), .black.opacity(0.25)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            )
            .shadow(color: tint.opacity(configuration.isPressed ? 0.15 : 0.4), radius: configuration.isPressed ? 4 : 10, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ResourcePill: View {
    var systemImage: String
    var value: String
    var tint: Color
    /// What the icon represents (e.g. "Gold", "Dream Gems") — read by
    /// VoiceOver ahead of `value` so this announces as one element
    /// ("1,234 Gold") instead of the icon and number being spoken separately.
    var accessibilityLabelText: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
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
        .accessibilityLabel("\(value) \(accessibilityLabelText)")
    }
}

/// Reusable ambient backdrop — the flat two-tone `Theme.background` plus a
/// couple of soft blurred glow blobs and a handful of slowly-twinkling
/// motes. Used behind every major screen (Dream Haven, Campaign, Inventory,
/// Shop, …) so nothing in the app shows a static, lifeless background.
/// Cheap: two blurred circles and ~7 tiny dots, no particle engine.
struct AmbientBackground: View {
    var topTint: Color = Theme.violet
    var bottomTint: Color = Theme.gold
    var topOffset: CGSize = CGSize(width: -150, height: -170)
    var bottomOffset: CGSize = CGSize(width: 170, height: 140)
    var showsSparkles: Bool = true

    var body: some View {
        ZStack {
            Theme.background

            Circle()
                .fill(topTint.opacity(0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 80)
                .offset(x: topOffset.width, y: topOffset.height)

            Circle()
                .fill(bottomTint.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 90)
                .offset(x: bottomOffset.width, y: bottomOffset.height)

            if showsSparkles {
                SparkleField()
            }
        }
        .ignoresSafeArea()
    }
}

/// A handful of tiny, slowly-twinkling dots drifting behind a screen —
/// shared by `AmbientBackground`.
struct SparkleField: View {
    private struct Mote {
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
    }

    private let motes: [Mote] = [
        Mote(x: 0.08, y: 0.12, size: 3, delay: 0),
        Mote(x: 0.24, y: 0.58, size: 2, delay: 0.5),
        Mote(x: 0.42, y: 0.22, size: 2.5, delay: 1.1),
        Mote(x: 0.63, y: 0.7, size: 2, delay: 0.25),
        Mote(x: 0.8, y: 0.32, size: 3, delay: 0.85),
        Mote(x: 0.92, y: 0.62, size: 2, delay: 1.4),
        Mote(x: 0.52, y: 0.88, size: 2.5, delay: 0.65),
    ]

    @State private var twinkle = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(motes.enumerated()), id: \.offset) { _, mote in
                    Circle()
                        .fill(Color.white)
                        .frame(width: mote.size, height: mote.size)
                        .position(x: geo.size.width * mote.x, y: geo.size.height * mote.y)
                        .opacity(twinkle ? 0.85 : 0.15)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(mote.delay),
                            value: twinkle
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { twinkle = true }
    }
}

/// Brief full-cover checkmark banner shown right before a sheet auto-dismisses
/// after a reward collect, so the player sees confirmation instead of just
/// watching the sheet vanish.
struct CollectConfirmation: View {
    var text: LocalizedStringKey
    var tint: Color

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(tint)
            Text(text)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Collected!")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(28)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.5), lineWidth: 1)
        )
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
}
