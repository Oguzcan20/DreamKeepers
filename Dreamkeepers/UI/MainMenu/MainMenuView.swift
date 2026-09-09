import SwiftUI

struct MainMenuView: View {
    var gameState: GameState
    var onPlay: () -> Void
    var onSettings: () -> Void

    @State private var appeared = false
    @State private var glowPulse = false
    @State private var breathing = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // Key art shown at its own proportions (no crop, no forced
            // fill-scale blow-up) — the landscape frame (~2.17:1) is much
            // wider than the source art (552×396, 1.39:1), so `.fit` renders
            // it noticeably smaller than edge-to-edge, letterboxed into the
            // shared dark background rather than stretched/cropped to cover.
            Image("DreamHavenBanner")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    LinearGradient(
                        colors: [Theme.deepNavy.opacity(0.35), .clear, .clear, Theme.deepNavy.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    // Extra scrim on the trailing edge only, so the CTA
                    // panel over there stays legible without darkening the
                    // rest of the scene.
                    LinearGradient(
                        colors: [.clear, .clear, Theme.deepNavy.opacity(0.55)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .ignoresSafeArea()

            MenuSparkleField()
                .allowsHitTesting(false)

            ctaPanel
                .padding(.trailing, 28)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .opacity(appeared ? 1 : 0)
                .offset(x: appeared ? 0 : 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }

    private var ctaPanel: some View {
        VStack(spacing: 14) {
            Text("A cozy fantasy RPG for a few quiet minutes at a time.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 220)

            Button {
                onPlay()
            } label: {
                Label("Play", systemImage: "play.fill")
                    .font(.title3.weight(.bold))
            }
            .buttonStyle(GlossyPlayButtonStyle())
            .scaleEffect(breathing ? 1.02 : 1.0)
            .shadow(color: Theme.gold.opacity(glowPulse ? 0.5 : 0.15), radius: glowPulse ? 20 : 8)
            .shadow(color: Theme.violet.opacity(glowPulse ? 0.65 : 0.3), radius: glowPulse ? 16 : 6)

            Button {
                onSettings()
            } label: {
                Label("Settings", systemImage: "gearshape.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 18)
        .padding(.horizontal, 20)
        .frame(width: 236)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.violet.opacity(0.16), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.35), Theme.gold.opacity(0.15), .white.opacity(0.06)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
    }
}

/// Compact, embossed jewel-toned primary button — a domed gradient fill,
/// glass highlight dome, gold bevel that's bright top-left/dark bottom-right
/// for real 3D relief, and a grounding drop shadow that presses in on tap.
private struct GlossyPlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 34)
            .padding(.vertical, 13)
            .background(
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.5, blue: 0.98),
                            Theme.violet,
                            Color(red: 0.36, green: 0.2, blue: 0.6),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    LinearGradient(
                        colors: [.white.opacity(0.55), .white.opacity(0.1), .clear],
                        startPoint: .top, endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                // Bevel rim: bright gold catching light top-left, fading to
                // shadow bottom-right — the classic raised-button cue.
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Theme.gold.opacity(0.95), Theme.gold.opacity(0.4),
                                Color.black.opacity(0.35),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .inset(by: 2)
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.75)
                    .blendMode(.overlay)
            )
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.2 : 0.45),
                radius: configuration.isPressed ? 4 : 12,
                y: configuration.isPressed ? 2 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Ambient dream-motes drifting slowly upward and fading over the scene —
/// keeps the background alive instead of reading as a static poster.
private struct MenuSparkleField: View {
    private struct Mote {
        var x: CGFloat
        var startY: CGFloat
        var scale: CGFloat
        var duration: Double
        var delay: Double
        var warm: Bool
    }

    private let motes: [Mote] = (0..<16).map { index in
        Mote(
            x: CGFloat.random(in: 0.05...0.95),
            startY: CGFloat.random(in: 0.2...1.05),
            scale: CGFloat.random(in: 0.4...1.3),
            duration: Double.random(in: 5...9),
            delay: Double(index) * 0.28,
            warm: index.isMultiple(of: 2)
        )
    }

    @State private var rise = false

    var body: some View {
        GeometryReader { geo in
            ForEach(motes.indices, id: \.self) { index in
                let mote = motes[index]
                Image(systemName: "sparkle")
                    .font(.system(size: 9 * mote.scale))
                    .foregroundStyle(mote.warm ? Theme.gold.opacity(0.6) : Color.white.opacity(0.5))
                    .blur(radius: mote.scale > 0.9 ? 0 : 0.5)
                    .position(
                        x: geo.size.width * mote.x,
                        y: geo.size.height * mote.startY - (rise ? geo.size.height * 0.55 : 0)
                    )
                    .opacity(rise ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: mote.duration).repeatForever(autoreverses: false).delay(mote.delay),
                        value: rise
                    )
            }
        }
        .onAppear { rise = true }
    }
}
