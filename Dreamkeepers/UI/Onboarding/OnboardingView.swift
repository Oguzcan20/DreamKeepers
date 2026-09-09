import SwiftUI

/// First-launch walkthrough covering the four systems a brand-new player
/// can't infer just by looking at Dream Haven: Summoning, Fusion, Team
/// building, and the Campaign. Shown once — `RootView` overlays this atop
/// Dream Haven only while `!gameState.hasSeenOnboarding`, and `onFinish`
/// marks it seen so it never reappears for that save.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var pageIndex = 0
    @State private var appeared = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            tint: Theme.violet,
            title: "Summoning Shrine",
            body: "Spend Dream Gems at the Summoning Shrine to recruit new Dreamkeepers. Odds are shown up front — no hidden mechanics. A 10x Summon always includes a bonus pull for free."
        ),
        OnboardingPage(
            icon: "star.fill",
            tint: Theme.gold,
            title: "Fusion",
            body: "Summoning a Dreamkeeper you already own doesn't waste it — the duplicate goes straight to your Inventory. Fuse duplicates onto that Dreamkeeper there to raise its star tier and make it stronger."
        ),
        OnboardingPage(
            icon: "person.3.fill",
            tint: Theme.softBlue,
            title: "Team",
            body: "Build a team from your roster in the Inventory screen. Only deployed Dreamkeepers fight in battle and train at the Training Garden — keep your best team on deck."
        ),
        OnboardingPage(
            icon: "map.fill",
            tint: Theme.violet,
            title: "Campaign",
            body: "Send your team into the Campaign to clear stages, earn gold and EXP, and defeat bosses. Boss victories recruit your next Dreamkeeper automatically."
        )
    ]

    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingCard(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(width: 460, height: 260)

                pageDots

                HStack(spacing: 12) {
                    if !isLastPage {
                        Button("Skip") {
                            finish()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(isLastPage ? "Let's Go!" : "Next") {
                        if isLastPage {
                            finish()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) { pageIndex += 1 }
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    .frame(width: 160)
                }
                .frame(width: 460)

                Spacer(minLength: 0)
            }
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96)
        }
        // Fixed 460pt-wide card + button row, no ScrollView — comfortable
        // on an iPhone 17 Pro-class screen but tight against an iPhone
        // SE-class landscape height, so scale the whole overlay down
        // uniformly rather than let it clip against the smaller safe area.
        .adaptiveScale()
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == pageIndex ? Theme.gold : Color.white.opacity(0.25))
                    .frame(width: index == pageIndex ? 18 : 6, height: 6)
                    .animation(.easeOut(duration: 0.2), value: pageIndex)
            }
        }
        .accessibilityHidden(true)
    }

    private func finish() {
        withAnimation(.easeOut(duration: 0.25)) { appeared = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onFinish() }
    }
}

private struct OnboardingPage {
    var icon: String
    var tint: Color
    var title: String
    var body: String
}

private struct OnboardingCard: View {
    let page: OnboardingPage

    var body: some View {
        GlassCard {
            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(page.tint.opacity(0.3)).frame(width: 64, height: 64)
                        .shadow(color: page.tint.opacity(0.5), radius: 14)
                    Image(systemName: page.icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(LocalizedStringKey(page.title))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(page.body))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
