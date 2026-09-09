import Foundation

/// Platform- and backend-independent save contract. `LocalSaveStore` is the
/// only implementation today; a future `CloudSaveStore` (account sync) drops
/// in behind the same protocol.
protocol SaveSystem {
    func load() -> GameSave?
    func save(_ save: GameSave) throws
}

final class LocalSaveStore: SaveSystem {
    private let fileURL: URL
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
        self.fileURL = platform.appStorageDirectory.appendingPathComponent("save.json")
    }

    func load() -> GameSave? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(GameSave.self, from: data)
    }

    func save(_ save: GameSave) throws {
        let data = try encoder.encode(save)
        try data.write(to: fileURL, options: .atomic)
    }
}
