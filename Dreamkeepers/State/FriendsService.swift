import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Real cross-device friends: an 8-digit code to find each other by, mutual
/// friend lists, and live progress/online status — backed by Firebase
/// (Anonymous Auth for device identity + Firestore for the social graph),
/// since none of that is achievable with Game Center or CloudKit alone (see
/// `Dreamkeepers.entitlements`'s comment on why CloudKit is unavailable on a
/// free Apple Developer account).
///
/// Deliberately inert rather than crashing when `GoogleService-Info.plist`
/// hasn't been dropped into the project yet — `FirebaseApp.configure()`
/// aborts the process if it can't find that file, so `isConfigured` gates
/// every other call and the rest of the app keeps working with the Friends
/// screen simply showing a "not set up yet" state.
@MainActor
@Observable
final class FriendsService {
    struct Friend: Identifiable, Equatable {
        let id: String
        var friendCode: String
        var playerLevel: Int
        var currentStage: Int
        var lastActiveAt: Date

        /// Re-evaluated against `Date()` on every access — callers that want
        /// this to visibly tick over time (e.g. a friend going idle) should
        /// re-read it from a periodically-refreshing view like `TimelineView`
        /// rather than caching the value.
        var isOnline: Bool {
            Date().timeIntervalSince(lastActiveAt) < FriendsService.onlineWindowSeconds
        }
    }

    /// How recently `lastActiveAt` must have been touched (by the heartbeat
    /// below) for a friend to still read as online. `nonisolated` (and a
    /// plain constant) so `Friend.isOnline` — a nested, non-actor-isolated
    /// type — can read it without hopping to the main actor.
    nonisolated static let onlineWindowSeconds: TimeInterval = 120
    private static let heartbeatInterval: TimeInterval = 60
    private static let friendCodeDigits = 8

    private(set) var isConfigured: Bool
    private(set) var isReady = false
    private(set) var myFriendCode: String?
    private(set) var friends: [Friend] = []
    private(set) var lastError: String?
    private(set) var isAddingFriend = false

    private var db: Firestore?
    private var uid: String?
    // `nonisolated(unsafe)`: `deinit` is always a nonisolated context, and
    // these are cleaned up there. Both `Task.cancel()` and
    // `ListenerRegistration.remove()` are documented as safe to call from
    // any thread, so cleanup there is fine — Swift only allows plain
    // `nonisolated` on immutable stored properties, so `(unsafe)` is
    // required here regardless of `@Observable`/`@ObservationIgnored`.
    @ObservationIgnored nonisolated(unsafe) private var heartbeatTask: Task<Void, Never>?
    @ObservationIgnored nonisolated(unsafe) private var myProfileListener: ListenerRegistration?
    @ObservationIgnored nonisolated(unsafe) private var friendsListener: ListenerRegistration?
    private var lastKnownFriendIDs: [String] = []

    init() {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            isConfigured = false
            return
        }
        isConfigured = true
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        db = Firestore.firestore()
    }

    deinit {
        heartbeatTask?.cancel()
        myProfileListener?.remove()
        friendsListener?.remove()
    }

    /// Signs in anonymously (silent, no credentials, no personal data),
    /// ensures a Firestore profile with a stable friend code exists, then
    /// starts the presence heartbeat and live friends listener. Safe to call
    /// repeatedly — a no-op once already ready.
    func start(playerLevel: Int, currentStage: Int) {
        guard isConfigured, !isReady else { return }
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                guard let user = result?.user else {
                    self.lastError = error?.localizedDescription ?? "Anmeldung fehlgeschlagen."
                    return
                }
                self.uid = user.uid
                await self.ensureProfile(playerLevel: playerLevel, currentStage: currentStage)
                self.isReady = true
                self.listenToOwnProfile()
                self.startHeartbeat()
            }
        }
    }

    /// Called whenever the player's level or campaign stage changes so
    /// friends see current progress, not just what it was at last launch.
    func updateMyProgress(playerLevel: Int, currentStage: Int) {
        guard isReady, let db, let uid else { return }
        db.collection("players").document(uid).updateData([
            "playerLevel": playerLevel,
            "currentStage": currentStage
        ])
    }

    /// Looks the code up, then adds each player to the other's friend list
    /// in one atomic batch — mutual by construction, no accept step.
    @discardableResult
    func addFriend(code: String) async -> Bool {
        guard isReady, let db, let uid else { return false }
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == Self.friendCodeDigits, trimmed.allSatisfy(\.isNumber) else {
            lastError = "Freundescode muss aus 8 Ziffern bestehen."
            return false
        }
        isAddingFriend = true
        lastError = nil
        defer { isAddingFriend = false }
        do {
            let codeDoc = try await db.collection("friendCodes").document(trimmed).getDocument()
            guard let friendID = codeDoc.get("playerID") as? String else {
                lastError = "Kein Spieler mit diesem Code gefunden."
                return false
            }
            guard friendID != uid else {
                lastError = "Das ist dein eigener Code."
                return false
            }
            guard !lastKnownFriendIDs.contains(friendID) else {
                lastError = "Ist schon dein Freund."
                return false
            }
            let batch = db.batch()
            batch.updateData(["friendIDs": FieldValue.arrayUnion([friendID])],
                              forDocument: db.collection("players").document(uid))
            batch.updateData(["friendIDs": FieldValue.arrayUnion([uid])],
                              forDocument: db.collection("players").document(friendID))
            try await batch.commit()
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func ensureProfile(playerLevel: Int, currentStage: Int) async {
        guard let db, let uid else { return }
        let ref = db.collection("players").document(uid)
        do {
            let snapshot = try await ref.getDocument()
            if snapshot.exists, let code = snapshot.get("friendCode") as? String {
                myFriendCode = code
                try await ref.updateData([
                    "playerLevel": playerLevel,
                    "currentStage": currentStage,
                    "lastActiveAt": FieldValue.serverTimestamp()
                ])
            } else {
                let code = try await generateUniqueFriendCode()
                try await ref.setData([
                    "friendCode": code,
                    "playerLevel": playerLevel,
                    "currentStage": currentStage,
                    "friendIDs": [String](),
                    "lastActiveAt": FieldValue.serverTimestamp()
                ])
                try await db.collection("friendCodes").document(code).setData(["playerID": uid])
                myFriendCode = code
            }
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func generateUniqueFriendCode() async throws -> String {
        guard let db else { throw FriendsServiceError.notConfigured }
        let upperBound = Int(pow(10.0, Double(Self.friendCodeDigits))) - 1
        for _ in 0..<10 {
            let code = String(format: "%0\(Self.friendCodeDigits)d", Int.random(in: 0...upperBound))
            let doc = try await db.collection("friendCodes").document(code).getDocument()
            if !doc.exists { return code }
        }
        throw FriendsServiceError.codeGenerationFailed
    }

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.sendHeartbeat()
                try? await Task.sleep(for: .seconds(Self.heartbeatInterval))
            }
        }
    }

    private func sendHeartbeat() async {
        guard let db, let uid else { return }
        try? await db.collection("players").document(uid).updateData([
            "lastActiveAt": FieldValue.serverTimestamp()
        ])
    }

    private func listenToOwnProfile() {
        guard let db, let uid else { return }
        myProfileListener?.remove()
        myProfileListener = db.collection("players").document(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let data = snapshot?.data() else { return }
                let ids = (data["friendIDs"] as? [String]) ?? []
                if ids != self.lastKnownFriendIDs {
                    self.lastKnownFriendIDs = ids
                    self.listenToFriends(ids: ids)
                }
            }
    }

    private func listenToFriends(ids: [String]) {
        friendsListener?.remove()
        guard let db, !ids.isEmpty else {
            friends = []
            return
        }
        // Firestore `in` queries cap at 30 values — a mobile gacha game's
        // friend list realistically never gets close, but chunk defensively.
        let chunk = Array(ids.prefix(30))
        friendsListener = db.collection("players")
            .whereField(FieldPath.documentID(), in: chunk)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.friends = docs.map { doc in
                    let data = doc.data()
                    let lastActive = (data["lastActiveAt"] as? Timestamp)?.dateValue() ?? .distantPast
                    return Friend(
                        id: doc.documentID,
                        friendCode: data["friendCode"] as? String ?? "--------",
                        playerLevel: data["playerLevel"] as? Int ?? 1,
                        currentStage: data["currentStage"] as? Int ?? 1,
                        lastActiveAt: lastActive
                    )
                }.sorted { $0.playerLevel > $1.playerLevel }
            }
    }
}

private enum FriendsServiceError: Error {
    case notConfigured
    case codeGenerationFailed
}
