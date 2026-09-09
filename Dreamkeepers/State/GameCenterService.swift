import Foundation
import Observation
import GameKit
import UIKit

/// Real "compete against friends" infrastructure via Apple's own Game
/// Center — no custom backend, works today even on a free developer
/// account (unlike Sign in with Apple / iCloud, which need a paid Apple
/// Developer Program membership). Friends and the native Game Center
/// overlay work out of the box; per-app Leaderboards additionally need a
/// leaderboard ID configured in App Store Connect, which itself needs a
/// paid account — that step is deliberately not built here yet.
@MainActor
@Observable
final class GameCenterService: NSObject {
    private(set) var isAuthenticated = false
    private(set) var displayName: String?
    private(set) var friendCount: Int?
    private(set) var authError: String?

    /// Set by the SwiftUI layer so the system login sheet (if Game Center
    /// needs one) has somewhere to present from.
    var presentingViewController: (() -> UIViewController?)?

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.presentingViewController?()?.present(viewController, animated: true)
                    return
                }
                if let error {
                    self.authError = error.localizedDescription
                    self.isAuthenticated = false
                    return
                }
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self.displayName = GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.alias : nil
                self.authError = nil
                if GKLocalPlayer.local.isAuthenticated {
                    self.loadFriendCount()
                }
            }
        }
    }

    private func loadFriendCount() {
        Task { @MainActor in
            guard GKLocalPlayer.local.isUnderage == false else { return }
            do {
                let friends = try await GKLocalPlayer.local.loadFriends()
                self.friendCount = friends.count
            } catch {
                // Friend access can be denied by the player or restricted —
                // that's a normal, non-fatal outcome, not an app error.
                self.friendCount = nil
            }
        }
    }
}
