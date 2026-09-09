import SwiftUI
import AuthenticationServices

struct SettingsView: View {
    var gameState: GameState
    var accountState: AccountState
    var gameCenterService: GameCenterService
    var navigate: (AppRoute) -> Void

    @State private var showResetConfirmation = false
    @State private var showGameCenterOverlay = false
    @State private var showLeaderboardOverlay = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 14) {
                        accountCard
                        gameCenterCard
                        languageCard
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 14) {
                        GlassCard {
                            Toggle(isOn: Binding(
                                get: { gameState.soundEnabled },
                                set: { gameState.setSoundEnabled($0) }
                            )) {
                                Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                                    .foregroundStyle(.white)
                            }
                            .tint(Theme.violet)
                        }

                        GlassCard {
                            Toggle(isOn: Binding(
                                get: { gameState.hapticsEnabled },
                                set: { gameState.setHapticsEnabled($0) }
                            )) {
                                Label("Haptics", systemImage: "hand.tap.fill")
                                    .foregroundStyle(.white)
                            }
                            .tint(Theme.violet)
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Toggle(isOn: Binding(
                                    get: { gameState.notificationsEnabled },
                                    // The toggle shows the tapped value immediately, then
                                    // reflects whatever `gameState.notificationsEnabled`
                                    // ends up as once the system prompt resolves — it
                                    // snaps back on its own if the player declines.
                                    set: { gameState.setNotificationsEnabled($0) }
                                )) {
                                    Label("Notifications", systemImage: "bell.fill")
                                        .foregroundStyle(.white)
                                }
                                .tint(Theme.violet)
                                Text("Get notified when the Gold Fountain or Training Garden is full, about daily missions, and when your Login Bonus is ready.")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Your Data", systemImage: "lock.fill")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("Progress is stored on this device and, when iCloud is available, synced privately to your other devices. Dreamkeepers doesn't collect or share personal data.")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Text("Reset Progress")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Text("Dreamkeepers · v\(appVersion)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.35))

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .frame(minHeight: 340)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .background(GameCenterOverlay(isPresented: $showGameCenterOverlay))
        .background(GameCenterOverlay(isPresented: $showLeaderboardOverlay, leaderboardID: LeaderboardService.campaignProgressID))
        .confirmationDialog(
            "Reset all progress?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Progress", role: .destructive) {
                gameState.resetProgress()
                navigate(.dreamHaven)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your Dreamkeepers, gold, gems, and campaign progress. This can't be undone.")
        }
    }

    @ViewBuilder
    private var accountCard: some View {
        GlassCard {
            if accountState.isSignedIn {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Theme.violet.opacity(0.3)).frame(width: 44, height: 44)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(accountState.displayName ?? "Dreamkeeper")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Signed in with Apple")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button("Sign Out") {
                        accountState.signOut()
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                VStack(spacing: 10) {
                    Label("Account", systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Sign in to keep your account ready for friends and cross-device play.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        handleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    @ViewBuilder
    private var gameCenterCard: some View {
        GlassCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.softBlue.opacity(0.3)).frame(width: 44, height: 44)
                    Image(systemName: "person.3.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Center")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    if gameCenterService.isAuthenticated {
                        if let count = gameCenterService.friendCount {
                            Text("\(gameCenterService.displayName ?? "") · \(count) friends")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                        } else {
                            Text(gameCenterService.displayName ?? "Signed in")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    } else {
                        Text("Not signed in")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                Spacer()
                if gameCenterService.isAuthenticated {
                    VStack(alignment: .trailing, spacing: 6) {
                        Button("Friends") {
                            showGameCenterOverlay = true
                        }
                        Button("Leaderboard") {
                            showLeaderboardOverlay = true
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.softBlue)
                }
            }
        }
    }

    private var languageCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Language", systemImage: "globe")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                HStack(spacing: 10) {
                    LanguageOptionButton(title: "Deutsch", isSelected: gameState.preferredLanguage == "de") {
                        gameState.setPreferredLanguage("de")
                        gameState.playHaptic(.light)
                    }
                    LanguageOptionButton(title: "English", isSelected: gameState.preferredLanguage != "de") {
                        gameState.setPreferredLanguage("en")
                        gameState.playHaptic(.light)
                    }
                }
            }
        }
    }

    private func handleSignIn(_ result: Result<ASAuthorization, Error>) {
        guard case .success(let authorization) = result,
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        accountState.signIn(userID: credential.user, displayName: name.isEmpty ? nil : name)
        gameState.playHaptic(.success)
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
            Text("Settings")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}

private struct LanguageOptionButton: View {
    let title: String
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Theme.gold : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
