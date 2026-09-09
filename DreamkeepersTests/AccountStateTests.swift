import XCTest
@testable import Dreamkeepers

final class AccountStateTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AccountStateTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    func testStartsSignedOut() {
        let state = AccountState(defaults: makeDefaults())
        XCTAssertFalse(state.isSignedIn)
        XCTAssertNil(state.displayName)
        XCTAssertNil(state.appleUserID)
    }

    func testSignInCapturesUserIDAndDisplayName() {
        let state = AccountState(defaults: makeDefaults())
        state.signIn(userID: "user_123", displayName: "Ash Ketchum")

        XCTAssertTrue(state.isSignedIn)
        XCTAssertEqual(state.appleUserID, "user_123")
        XCTAssertEqual(state.displayName, "Ash Ketchum")
    }

    func testSignInWithoutANameKeepsAnyPreviouslyCapturedName() {
        let state = AccountState(defaults: makeDefaults())
        state.signIn(userID: "user_123", displayName: "Ash Ketchum")

        // Apple only returns fullName on the very first authorization —
        // subsequent sign-ins pass nil and must not erase the stored name.
        state.signIn(userID: "user_123", displayName: nil)

        XCTAssertEqual(state.displayName, "Ash Ketchum")
    }

    func testSignOutClearsEverything() {
        let state = AccountState(defaults: makeDefaults())
        state.signIn(userID: "user_123", displayName: "Ash Ketchum")

        state.signOut()

        XCTAssertFalse(state.isSignedIn)
        XCTAssertNil(state.displayName)
        XCTAssertNil(state.appleUserID)
    }

    func testSignInStatePersistsAcrossInstancesSharingDefaults() {
        let defaults = makeDefaults()
        let state = AccountState(defaults: defaults)
        state.signIn(userID: "user_123", displayName: "Ash Ketchum")

        let reloaded = AccountState(defaults: defaults)

        XCTAssertTrue(reloaded.isSignedIn)
        XCTAssertEqual(reloaded.appleUserID, "user_123")
        XCTAssertEqual(reloaded.displayName, "Ash Ketchum")
    }

    func testSignOutPersistsAcrossInstancesSharingDefaults() {
        let defaults = makeDefaults()
        let state = AccountState(defaults: defaults)
        state.signIn(userID: "user_123", displayName: "Ash Ketchum")
        state.signOut()

        let reloaded = AccountState(defaults: defaults)

        XCTAssertFalse(reloaded.isSignedIn)
    }
}
