import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// The cross-player side of the World Boss event: every player fights the
/// boss alone (see `WorldBossSystem`'s doc comment), and this is what ties
/// those solo fights into one weekly leaderboard — a Firestore doc per
/// player per week, holding just their running total damage. Mirrors
/// `FriendsService`'s shape (Anonymous Auth for device identity, inert
/// rather than crashing when `GoogleService-Info.plist` is missing) exactly,
/// including being safe to `start()` a second time independently — both
/// services resolve to the same device-cached Firebase uid.
@MainActor
@Observable
final class WorldBossLeaderboardService {
    struct Entry: Identifiable, Equatable {
        let id: String
        var damage: Int
        var playerLevel: Int
    }

    private(set) var isConfigured: Bool
    private(set) var isReady = false
    private(set) var top: [Entry] = []
    /// This player's own standing for the currently-listened week — `nil`
    /// until the first successful fetch, or if they haven't dealt any
    /// damage yet this week.
    private(set) var myRank: Int?
    private(set) var myDamage: Int = 0
    private(set) var lastError: String?

    private var db: Firestore?
    private var uid: String?
    @ObservationIgnored nonisolated(unsafe) private var topListener: ListenerRegistration?
    /// The week this instance is currently listening/submitting for — guards
    /// against a stale listener callback (from a just-replaced week) writing
    /// into `top`/`myRank` after `listen(weekID:)` has already moved on.
    private var listenedWeekID: String?

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
        topListener?.remove()
    }

    /// Signs in anonymously (idempotent — safe alongside `FriendsService`'s
    /// own sign-in, both resolve to the same cached uid) then starts a live
    /// listener on this week's top entries. Safe to call repeatedly.
    func start() {
        guard isConfigured, !isReady else { return }
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                guard let user = result?.user else {
                    self.lastError = error?.localizedDescription ?? "Anmeldung fehlgeschlagen."
                    return
                }
                self.uid = user.uid
                self.isReady = true
            }
        }
    }

    /// Writes this player's running total for `weekID`, then refreshes
    /// `myRank` — called once per attack from `RootView` right after
    /// `GameState.applyWorldBossBattleResult`.
    func submitDamage(weekID: String, totalDamage: Int, playerLevel: Int) {
        guard isReady, let db, let uid else { return }
        myDamage = totalDamage
        db.collection("worldBossLeaderboard").document(weekID).collection("entries").document(uid).setData([
            "damage": totalDamage,
            "playerLevel": playerLevel,
            "updatedAt": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] _ in
            Task { @MainActor in self?.refreshMyRank(weekID: weekID, totalDamage: totalDamage) }
        }
    }

    /// Starts (or moves) the live top-N listener for `weekID` — call once
    /// when `WorldBossView` appears. A no-op if already listening to the
    /// same week.
    func listen(weekID: String, limit: Int = 200) {
        guard isReady, let db else { return }
        guard listenedWeekID != weekID else { return }
        listenedWeekID = weekID
        topListener?.remove()
        topListener = db.collection("worldBossLeaderboard").document(weekID).collection("entries")
            .order(by: "damage", descending: true)
            .limit(to: limit)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self, let docs = snapshot?.documents else { return }
                self.top = docs.map { doc in
                    let data = doc.data()
                    return Entry(
                        id: doc.documentID,
                        damage: data["damage"] as? Int ?? 0,
                        playerLevel: data["playerLevel"] as? Int ?? 1
                    )
                }
                if let uid = self.uid, let mine = self.top.firstIndex(where: { $0.id == uid }) {
                    self.myRank = mine + 1
                }
            }
    }

    /// A player past the top-N listener's window (`limit`) needs their exact
    /// rank computed separately — an aggregate `count()` query of everyone
    /// who out-damaged them, rather than downloading the whole collection.
    private func refreshMyRank(weekID: String, totalDamage: Int) {
        guard let db, let uid else { return }
        guard totalDamage > 0 else { return }
        if let mine = top.firstIndex(where: { $0.id == uid }) {
            myRank = mine + 1
            return
        }
        let query = db.collection("worldBossLeaderboard").document(weekID).collection("entries")
            .whereField("damage", isGreaterThan: totalDamage)
        query.count.getAggregation(source: .server) { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            Task { @MainActor in
                self.myRank = Int(truncating: snapshot.count) + 1
            }
        }
    }

    func stopListening() {
        topListener?.remove()
        topListener = nil
        listenedWeekID = nil
    }
}
