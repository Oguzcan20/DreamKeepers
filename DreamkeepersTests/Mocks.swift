import Foundation
@testable import Dreamkeepers

final class MockPlatformService: PlatformService {
    /// Defaults to the shared temp directory; tests that need a guaranteed-
    /// empty directory (e.g. asserting `load()` returns nil) can override it.
    var appStorageDirectoryOverride: URL?
    var appStorageDirectory: URL { appStorageDirectoryOverride ?? FileManager.default.temporaryDirectory }
    private(set) var hapticCallCount = 0
    private(set) var soundCallCount = 0
    func playHaptic(_ style: HapticStyle) { hapticCallCount += 1 }
    func playSound(_ effect: SoundEffect) { soundCallCount += 1 }

    /// Tests can flip this to exercise the "player denied notifications" path.
    var notificationAuthorizationGranted = true
    private(set) var scheduledNotificationIDs: [String] = []
    private(set) var cancelledNotificationIDs: [String] = []
    private(set) var cancelAllNotificationsCallCount = 0

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        completion(notificationAuthorizationGranted)
    }
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) {
        scheduledNotificationIDs.append(id)
    }
    func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        scheduledNotificationIDs.append(id)
    }
    func cancelNotification(id: String) {
        cancelledNotificationIDs.append(id)
    }
    func cancelAllNotifications() {
        cancelAllNotificationsCallCount += 1
    }
}

final class InMemorySaveSystem: SaveSystem {
    private var stored: GameSave?

    func load() -> GameSave? { stored }
    func save(_ save: GameSave) throws { stored = save }
}
