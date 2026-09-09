import Foundation
import Observation

/// The player's Apple ID identity — separate from `GameState`/`SaveSystem`.
/// Save sync itself rides on the device's iCloud account automatically via
/// `CloudSaveStore` regardless of this; signing in here is about having a
/// recognizable account (display name, future leaderboards/friends) rather
/// than gating storage.
@Observable
final class AccountState {
    private(set) var isSignedIn: Bool
    private(set) var displayName: String?
    private(set) var appleUserID: String?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedUserID = defaults.string(forKey: Keys.userID)
        self.appleUserID = storedUserID
        self.displayName = defaults.string(forKey: Keys.displayName)
        self.isSignedIn = storedUserID != nil
    }

    /// Apple only hands back `fullName` the very first time a user
    /// authorizes this app, so `displayName` is optional here and, once
    /// captured, is kept even if a later sign-in omits it.
    func signIn(userID: String, displayName: String?) {
        appleUserID = userID
        defaults.set(userID, forKey: Keys.userID)
        if let displayName, !displayName.isEmpty {
            self.displayName = displayName
            defaults.set(displayName, forKey: Keys.displayName)
        }
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        appleUserID = nil
        displayName = nil
        defaults.removeObject(forKey: Keys.userID)
        defaults.removeObject(forKey: Keys.displayName)
    }

    private enum Keys {
        static let userID = "dreamkeepers.account.appleUserID"
        static let displayName = "dreamkeepers.account.displayName"
    }
}
