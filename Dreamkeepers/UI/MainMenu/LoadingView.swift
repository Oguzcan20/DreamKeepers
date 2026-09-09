import SwiftUI

/// App-launch splash — full-bleed key art with a simulated progress bar and a
/// random gameplay tip, shown once before the Main Menu appears. There's
/// nothing slow to actually wait on (save load is local/instant), so the
/// progress is a fixed-duration animation purely for pacing/branding, same
/// as most mobile games do.
struct LoadingView: View {
    var onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var tip: LocalizedStringKey = LoadingView.tips.randomElement() ?? "Match elements for an advantage against tough enemies."
    @State private var appeared = false

    private static let tips: [LocalizedStringKey] = [
        "Match elements for an advantage against tough enemies.",
        "Fuse duplicate Dreamkeepers to raise their star rank.",
        "Upgrade equipment from the Inventory to boost your team's stats.",
        "Collect offline rewards from the Gold Fountain and Training Garden.",
        "Complete Daily Missions for extra Gold and Gems.",
        "Deploy up to five Dreamkeepers per team — balance your elements.",
    ]

    var body: some View {
        ZStack {
            Theme.deepNavy.ignoresSafeArea()

            // Same treatment as MainMenuView: shown at its own proportions,
            // not blown up to fill the wider landscape frame.
            Image("DreamHavenBanner")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    LinearGradient(
                        colors: [.clear, .clear, Theme.deepNavy.opacity(0.55), Theme.deepNavy.opacity(0.92)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .ignoresSafeArea()

            VStack {
                Spacer()
                footer
                    .padding(.horizontal, 56)
                    .padding(.bottom, 22)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.6)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.85) {
                onFinished()
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Text("LOADING…")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(1)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.footnote.monospacedDigit().weight(.bold))
                    .foregroundStyle(Theme.gold)
            }

            progressBar

            tipRow
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Theme.violet, Color(red: 0.8, green: 0.42, blue: 0.92), Theme.gold],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(10, geo.size.width * progress))
            }
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Theme.gold.opacity(0.9), Theme.gold.opacity(0.3)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .frame(height: 10)
    }

    private var tipRow: some View {
        HStack(alignment: .top, spacing: 8) {
            ZStack {
                Circle().fill(Theme.gold.opacity(0.16)).frame(width: 20, height: 20)
                Image(systemName: "star.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.gold)
            }
            (Text("TIP: ").foregroundStyle(Theme.gold).fontWeight(.bold) + Text(tip).foregroundStyle(.white.opacity(0.85)))
                .font(.caption)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
        }
    }
}
