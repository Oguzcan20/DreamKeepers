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
struct StarterOlfChoiceView: View {
    var onChoose: (Element?) -> Void

    @State private var appeared = false
    @State private var resolved = false
    @State private var emberHoldProgress: Double = 0

    private let holdDuration: TimeInterval = 5

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            GlassCard {
                VStack(spacing: 18) {
                    VStack(spacing: 6) {
                        Text("Choose Olf's Element")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text("This sticks with him for good — pick whatever feels right.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                        ForEach(Element.allCases) { element in
                            if element == .ember {
                                emberTile
                            } else {
                                elementTile(element)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: 420)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96)
        }
        // The default (874×402) reference is tuned for wide, short
        // landscape hub screens (see `AdaptiveScale`'s doc comment) — this
        // card is taller/narrower than that (title + subtitle + a 3x2
        // element grid), so the default squeezes it into too little height
        // and would run out of vertical room on shorter landscape phones
        // (iPhone SE-class). A taller custom reference gives the VStack
        // comfortable room before the whole card gets uniformly scaled
        // down to fit the real device. Mirrors the fix in the Flutter
        // port's `starter_olf_choice_view.dart`.
        .adaptiveScale(reference: CGSize(width: 480, height: 620))
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
        }
    }

    private func elementTile(_ element: Element) -> some View {
        Button {
            choose(element)
        } label: {
            elementTileLabel(element)
        }
        .buttonStyle(.plain)
        .disabled(resolved)
    }

    /// The Ember tile carries the secret: a plain tap still picks Ember
    /// normally, but holding it down for `holdDuration` fires `perform`
    /// instead and the release that follows is swallowed by `resolved`
    /// already being true — so the player never also gets a normal Ember
    /// pick immediately after unlocking the ultimate one.
    private var emberTile: some View {
        elementTileLabel(.ember)
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
                onChoose(nil)
            } onPressingChanged: { isPressing in
                guard !resolved else { return }
                if isPressing {
                    withAnimation(.linear(duration: holdDuration)) { emberHoldProgress = 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) { emberHoldProgress = 0 }
                }
            }
    }

    private func elementTileLabel(_ element: Element) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(element.color.opacity(0.3)).frame(width: 52, height: 52)
                    .shadow(color: element.color.opacity(0.5), radius: 10)
                Image(systemName: element.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Text(element.displayName)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(element.displayName)
    }

    private func choose(_ element: Element) {
        guard !resolved else { return }
        resolved = true
        onChoose(element)
    }
}

#Preview {
    StarterOlfChoiceView(onChoose: { _ in })
}
