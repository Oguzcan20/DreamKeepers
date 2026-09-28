import Foundation
import Observation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

/// Claims a globally-unique player name after onboarding — backed by
/// Firebase (the same Anonymous Auth session `FriendsService` establishes +
/// Firestore for the reservation), since a human-chosen value has far higher
/// collision risk than `FriendsService`'s random 8-digit friend codes, so a
/// simple get-then-set check isn't safe here: a Firestore transaction is
/// used instead, so two players racing for the same popular name can never
/// both win it.
///
/// Deliberately inert rather than crashing when `GoogleService-Info.plist`
/// hasn't been dropped into the project yet — see `FriendsService`'s doc
/// comment for why; `isConfigured` gates every call the same way here.
@MainActor
@Observable
final class PlayerNameService {
    enum ValidationError: LocalizedError, Equatable {
        case tooShort
        case tooLong
        case invalidCharacters

        var errorDescription: String? {
            switch self {
            case .tooShort:
                return "Name muss mindestens \(PlayerNameService.minLength) Zeichen lang sein."
            case .tooLong:
                return "Name darf höchstens \(PlayerNameService.maxLength) Zeichen lang sein."
            case .invalidCharacters:
                return "Nur Buchstaben, Zahlen und Unterstriche erlaubt."
            }
        }
    }

    enum ClaimError: LocalizedError, Equatable {
        case notConfigured
        case invalid(ValidationError)
        case alreadyTaken
        case other(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "Namensvergabe derzeit nicht verfügbar."
            case .invalid(let validationError):
                return validationError.errorDescription
            case .alreadyTaken:
                return "Dieser Name ist schon vergeben."
            case .other(let message):
                return message
            }
        }
    }

    // Plain constants, not view state — `nonisolated` so `ValidationError`
    // (a non-actor nested type) and other nonisolated contexts can read them
    // without hopping to the main actor.
    nonisolated static let minLength = 3
    nonisolated static let maxLength = 16
    private nonisolated static let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

    private(set) var isConfigured: Bool
    private(set) var isClaiming = false

    private var db: Firestore?

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

    /// Syntactic validation only — no network call. Used for inline
    /// as-you-type feedback before the player submits.
    static func validate(_ rawName: String) -> ValidationError? {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < minLength { return .tooShort }
        if trimmed.count > maxLength { return .tooLong }
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .invalidCharacters
        }
        return nil
    }

    /// Atomically claims `rawName` for this device's Firebase user (signing
    /// in anonymously first if no session exists yet — idempotent, shares
    /// the same Firebase Auth session `FriendsService` uses). Uniqueness is
    /// case-insensitive (`playerNames/{lowercased}`), but the exact casing
    /// the player typed is preserved as the stored/displayed name. Safe to
    /// retry: re-claiming a name this same user already owns succeeds again
    /// rather than reporting it taken.
    @discardableResult
    func claim(_ rawName: String) async -> Result<String, ClaimError> {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let validationError = Self.validate(trimmed) {
            return .failure(.invalid(validationError))
        }
        // No Firebase project configured for this build (see `FriendsService`'s
        // doc comment on the same gate) — there's no server to enforce global
        // uniqueness against, so accept the name locally rather than
        // permanently blocking onboarding on an environment that can never
        // satisfy this screen.
        guard isConfigured, let db else { return .success(trimmed) }
        let normalized = trimmed.lowercased()

        isClaiming = true
        defer { isClaiming = false }

        let uid: String
        do {
            uid = try await ensureSignedIn()
        } catch {
            return .failure(.other(error.localizedDescription))
        }

        let nameRef = db.collection("playerNames").document(normalized)
        do {
            // The Swift-native `async throws -> Any` overload of
            // `runTransaction` requires its closure to be `@Sendable`, which
            // the installed FirebaseFirestore version doesn't declare —
            // wrapping the classic completion-handler overload in a
            // continuation (same idiom as `ensureSignedIn()` above) sidesteps
            // that mismatch entirely.
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                // `@Sendable` here is load-bearing, not decorative: this closure is
                // written inside a `@MainActor` method, so without it Swift infers
                // MainActor isolation on the closure itself — but Firestore actually
                // invokes it on its own internal transaction queue, and the runtime's
                // actor-executor check traps (`EXC_BREAKPOINT` in
                // `dispatch_assert_queue_fail`) the instant a real transaction runs.
                // It only touches local values (`nameRef`, `uid`, `trimmed`) and its
                // own parameters, never `self`, so marking it Sendable is safe.
                db.runTransaction({ @Sendable transaction, errorPointer -> Any? in
                    let snapshot: DocumentSnapshot
                    do {
                        snapshot = try transaction.getDocument(nameRef)
                    } catch let fetchError as NSError {
                        errorPointer?.pointee = fetchError
                        return nil
                    }
                    if snapshot.exists, snapshot.get("playerID") as? String != uid {
                        errorPointer?.pointee = NSError(
                            domain: "PlayerNameService.alreadyTaken", code: 1
                        )
                        return nil
                    }
                    transaction.setData([
                        "playerID": uid,
                        "displayName": trimmed,
                        "claimedAt": FieldValue.serverTimestamp()
                    ], forDocument: nameRef)
                    return nil
                }, completion: { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                })
            }
            return .success(trimmed)
        } catch let error as NSError {
            if error.domain == "PlayerNameService.alreadyTaken" {
                return .failure(.alreadyTaken)
            }
            return .failure(.other(error.localizedDescription))
        }
    }

    private func ensureSignedIn() async throws -> String {
        if let user = Auth.auth().currentUser {
            return user.uid
        }
        return try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signInAnonymously { result, error in
                if let user = result?.user {
                    continuation.resume(returning: user.uid)
                } else {
                    continuation.resume(throwing: error ?? ClaimError.other("Anmeldung fehlgeschlagen."))
                }
            }
        }
    }
}
