import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

final class iOSPlatformService: PlatformService {
    var appStorageDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = urls[0].appendingPathComponent("Dreamkeepers", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func playHaptic(_ style: HapticStyle) {
        #if canImport(UIKit)
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .levelUp:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        #endif
    }

    func playSound(_ effect: SoundEffect) {
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(effect.systemSoundID)
        #endif
    }

    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async { completion(true) }
            case .denied:
                DispatchQueue.main.async { completion(false) }
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    DispatchQueue.main.async { completion(granted) }
                }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
        #else
        completion(false)
        #endif
    }

    func scheduleNotification(id: String, title: String, body: String, fireDate: Date) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let interval = fireDate.timeIntervalSinceNow
        guard interval > 1 else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        #endif
    }

    func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        #if canImport(UserNotifications)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        #endif
    }

    func cancelNotification(id: String) {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        #endif
    }

    func cancelAllNotifications() {
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        #endif
    }
}

#if canImport(AudioToolbox)
private extension SoundEffect {
    /// Built-in iOS system sound IDs, chosen only for a rough tonal fit
    /// (chime vs. tap vs. swoosh) — placeholders until real composed SFX
    /// ship. Values below 1200 are the long-stable "UI sound" range Apple
    /// has shipped with every iOS release.
    var systemSoundID: SystemSoundID {
        switch self {
        case .buttonTap: return 1104   // Tock — short, unobtrusive tap
        case .levelUp: return 1025     // Anticipate — bright ascending chime
        case .loot: return 1057        // Tink — light positive blip
        case .summon: return 1016      // Received-message swoosh
        case .skill: return 1103       // Tock (variant) — quick blip
        case .ultimate: return 1013    // Fuller chime for a bigger moment
        case .bossEncounter: return 1073 // Lower, more ominous tone
        case .reward: return 1057      // Tink — same positive blip as loot
        }
    }
}
#endif
