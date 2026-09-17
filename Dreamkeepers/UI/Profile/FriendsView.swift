import SwiftUI

/// Add friends by an 8-digit code, see their level/stage progress and
/// whether they're online right now. Backed by `FriendsService`
/// (Firebase) — shows a plain "not set up yet" card instead of any of the
/// real content when Firebase hasn't been configured for this build.
struct FriendsView: View {
    var friendsService: FriendsService
    var navigate: (AppRoute) -> Void

    @State private var codeInput = ""
    @FocusState private var codeFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            if !friendsService.isConfigured {
                notConfiguredCard
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        myCodeCard
                        addFriendCard
                        friendsListCard
                    }
                    .padding(20)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button {
                navigate(.profile)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Back")
            Spacer()
            Text("Friends")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var notConfiguredCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "person.2.slash.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white.opacity(0.4))
                Text("Friends Aren't Set Up Yet")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("This feature needs a one-time Firebase project setup. Once that's done, you'll be able to add friends by code here.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }

    private var myCodeCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Text("Your Friend Code")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let code = friendsService.myFriendCode {
                    HStack(spacing: 12) {
                        Text(formattedCode(code))
                            .font(.title2.monospacedDigit().weight(.bold))
                            .foregroundStyle(Theme.gold)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = code
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Copy code")
                    }
                } else {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Creating code…")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
    }

    private var addFriendCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Text("Add Friend")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    TextField("8-digit code", text: $codeInput)
                        .keyboardType(.numberPad)
                        .focused($codeFieldFocused)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .onChange(of: codeInput) { _, newValue in
                            let digitsOnly = newValue.filter(\.isNumber)
                            codeInput = String(digitsOnly.prefix(8))
                        }

                    Button {
                        codeFieldFocused = false
                        let code = codeInput
                        Task {
                            if await friendsService.addFriend(code: code) {
                                codeInput = ""
                            }
                        }
                    } label: {
                        if friendsService.isAddingFriend {
                            ProgressView().tint(.white)
                                .frame(width: 44, height: 40)
                        } else {
                            Text("Add")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(height: 40)
                                .padding(.horizontal, 16)
                        }
                    }
                    .background(codeInput.count == 8 ? Theme.violet : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(codeInput.count != 8 || friendsService.isAddingFriend)
                }

                if let error = friendsService.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var friendsListCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                Text("Your Friends (\(friendsService.friends.count))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if friendsService.friends.isEmpty {
                    Text("No friends added yet.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    TimelineView(.periodic(from: .now, by: 15)) { _ in
                        VStack(spacing: 8) {
                            ForEach(friendsService.friends) { friend in
                                FriendRow(friend: friend)
                            }
                        }
                    }
                }
            }
        }
    }

    private func formattedCode(_ code: String) -> String {
        guard code.count == 8 else { return code }
        let mid = code.index(code.startIndex, offsetBy: 4)
        return "\(code[code.startIndex..<mid]) \(code[mid...])"
    }
}

private struct FriendRow: View {
    let friend: FriendsService.Friend

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((friend.isOnline ? Theme.softBlue : Color.white).opacity(friend.isOnline ? 0.22 : 0.06))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundStyle(friend.isOnline ? Theme.softBlue : .white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(friend.playerLevel)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Stage \(friend.currentStage)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(friend.isOnline ? Color.green : Color.white.opacity(0.3))
                    .frame(width: 7, height: 7)
                Text(friend.isOnline ? "Online" : "Offline")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(friend.isOnline ? .green : .white.opacity(0.4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
