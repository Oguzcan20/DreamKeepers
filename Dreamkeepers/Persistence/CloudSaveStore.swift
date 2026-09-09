import Foundation

/// Syncs the save across the player's devices via their iCloud account —
/// no custom backend, no third-party account required (spec section 31:
/// "Plane Cloud Save... für eine spätere Version vor" — this is that later
/// version, using Apple's own infrastructure instead of a hosted service).
///
/// Always writes a local copy first as a safety net, then mirrors it into
/// the iCloud ubiquity container when available. If iCloud is signed out,
/// disabled, or the container isn't provisioned, every cloud operation is a
/// harmless no-op and the app runs local-only — exactly like `LocalSaveStore`.
final class CloudSaveStore: SaveSystem {
    private let local: LocalSaveStore
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(platform: PlatformService) {
        self.local = LocalSaveStore(platform: platform)
    }

    /// Nil whenever iCloud isn't available right now (signed out, disabled
    /// for this app, or Simulator without an iCloud session) — checked fresh
    /// each call since availability can change while the app is running.
    private var cloudFileURL: URL? {
        guard let container = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let docs = container.appendingPathComponent("Documents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: docs.path) {
            try? FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        }
        return docs.appendingPathComponent("save.json")
    }

    /// Prefers the cloud copy when both exist, since it may reflect progress
    /// made on another device — falls back to the local copy otherwise.
    func load() -> GameSave? {
        if let cloudURL = cloudFileURL,
           let data = try? Data(contentsOf: cloudURL),
           let save = try? decoder.decode(GameSave.self, from: data) {
            return save
        }
        return local.load()
    }

    func save(_ save: GameSave) throws {
        try local.save(save)
        guard let cloudURL = cloudFileURL else { return }
        let data = try encoder.encode(save)
        try? data.write(to: cloudURL, options: .atomic)
    }
}
