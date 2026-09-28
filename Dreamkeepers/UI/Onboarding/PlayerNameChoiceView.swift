import SwiftUI
import UIKit

/// Shown once, right after the starter Olf choice resolves — the player
/// picks a display name reserved globally via `PlayerNameService` (a
/// Firestore transaction, so two players racing for the same popular name
/// can never both win it). `onChoose` only fires once the claim actually
/// succeeds; `RootView` overlays this atop Dream Haven only while
/// `gameState.needsPlayerName`.
struct PlayerNameChoiceView: View {
    var playerNameService: PlayerNameService
    var onChoose: (String) -> Void

    @State private var name = ""
    @State private var appeared = false
    @State private var claimErrorMessage: String?
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var fieldFocused: Bool

    /// How far to shift the card up so it re-centers in the space still
    /// visible above the keyboard, rather than staying centered on the full
    /// screen and running under it. Expressed in `.adaptiveScale()`'s 874×402
    /// reference space (not raw device points) so the shift lands correctly
    /// once the whole view gets uniformly scaled to the real screen size.
    private var keyboardOffset: CGFloat {
        guard keyboardHeight > 0 else { return 0 }
        let screenHeight = UIScreen.dk_safeContentSize.height
        guard screenHeight > 0 else { return 0 }
        return (keyboardHeight / 2) / screenHeight * 402
    }

    private var validationError: PlayerNameService.ValidationError? {
        name.isEmpty ? nil : PlayerNameService.validate(name)
    }

    private var canSubmit: Bool {
        !name.isEmpty && validationError == nil && !playerNameService.isClaiming
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()

            GlassCard {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Theme.gold.opacity(0.3)).frame(width: 64, height: 64)
                            .shadow(color: Theme.gold.opacity(0.5), radius: 14)
                        Image(systemName: "person.text.rectangle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text("Choose Your Name")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("This is how other Dreamkeepers will see you. Every name can only be claimed once.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($fieldFocused)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(fieldBorderColor, lineWidth: 1)
                        )
                        .onChange(of: name) { _, newValue in
                            let filtered = newValue.filter { $0.isLetter || $0.isNumber || $0 == "_" }
                            name = String(filtered.prefix(PlayerNameService.maxLength))
                            claimErrorMessage = nil
                        }
                        .onSubmit(submit)

                    Group {
                        if let validationError {
                            Text(validationError.errorDescription ?? "")
                        } else if let claimErrorMessage {
                            Text(claimErrorMessage)
                        } else {
                            Text("\(PlayerNameService.minLength)–\(PlayerNameService.maxLength) characters — letters, numbers, underscore.")
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                    Button {
                        submit()
                    } label: {
                        if playerNameService.isClaiming {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Confirm")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.gold))
                    .disabled(!canSubmit)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            .frame(width: 380)
            .padding(.horizontal, 4)
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.96)
            .offset(y: -keyboardOffset)
            .animation(.easeOut(duration: 0.25), value: keyboardOffset)
        }
        .adaptiveScale()
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) { appeared = true }
            fieldFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
    }

    private var fieldBorderColor: Color {
        (validationError != nil || claimErrorMessage != nil) ? Color.red.opacity(0.6) : Color.white.opacity(0.1)
    }

    private func submit() {
        guard canSubmit else { return }
        fieldFocused = false
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            switch await playerNameService.claim(trimmed) {
            case .success(let claimedName):
                onChoose(claimedName)
            case .failure(let error):
                claimErrorMessage = error.errorDescription
            }
        }
    }
}

#Preview {
    PlayerNameChoiceView(playerNameService: PlayerNameService(), onChoose: { _ in })
}
