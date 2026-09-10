import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(AVFoundation)
import AVFoundation
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
        #if canImport(AVFoundation)
        if BattleSoundBank.shared.play(effect) { return }
        #endif
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
    /// Built-in iOS system sound IDs — the fallback path when a bundled
    /// composed cue (see `BattleSoundBank`) is missing or won't decode.
    /// Chosen only for a rough tonal fit (chime vs. tap vs. swoosh). Values
    /// below 1200 are the long-stable "UI sound" range Apple has shipped
    /// with every iOS release.
    var systemSoundID: SystemSoundID {
        switch self {
        case .buttonTap: return 1104   // Tock — short, unobtrusive tap
        case .levelUp: return 1025     // Anticipate — bright ascending chime
        case .loot: return 1057        // Tink — light positive blip
        case .summon: return 1016      // Received-message swoosh
        case .attack: return 1104      // Tock — dry, unobtrusive hit
        case .skill: return 1103       // Tock (variant) — quick blip
        case .ultimate: return 1013    // Fuller chime for a bigger moment
        case .bossEncounter: return 1073 // Lower, more ominous tone
        case .bossVictory: return 1025 // Anticipate — bright, celebratory
        case .reward: return 1057      // Tink — same positive blip as loot
        }
    }
}
#endif

#if canImport(AVFoundation)
/// Plays the composed cues bundled in `Resources/Audio/` via `AVAudioPlayer`
/// — the cinematic battle sounds plus the general UI cues (`summon`,
/// `levelUp`, `reward`, `buttonTap`) that used to be bare iOS system beeps.
/// Everything is main-thread (every `playSound` call site already is — the
/// battle tick runs on the main actor), so no locking.
///
/// Design notes:
/// - The session is `.playback` + `.mixWithOthers` so a boss sting is
///   audible even with the ring switch silenced (the player explicitly
///   wants to *hear* this), while never interrupting the user's own music
///   or a podcast.
/// - Each cue keeps a tiny pool of players so rapid re-triggers (two
///   Ultimates back to back) overlap instead of cutting each other off.
/// - `play` returns `false` when it has no file for the effect, so
///   `iOSPlatformService.playSound` falls through to the system-sound path
///   for the non-battle cues (button tap, loot, …).
///
/// `@unchecked Sendable`: every `playSound` call site is already on the main
/// thread (the battle tick runs on the main actor; UI callbacks likewise),
/// same single-thread contract the rest of `iOSPlatformService` relies on —
/// there is no real shared mutable state to protect.
final class BattleSoundBank: @unchecked Sendable {
    static let shared = BattleSoundBank()

    /// SoundEffect → bundled file basename (`.wav` in the main bundle).
    private static let fileName: [SoundEffect: String] = [
        .bossEncounter: "boss_encounter",
        .bossVictory: "boss_victory",
        .ultimate: "ultimate",
        .skill: "skill",
        .attack: "attack",
        .summon: "summon",
        .levelUp: "level_up",
        .reward: "reward",
        .buttonTap: "button_tap",
    ]

    /// Per-cue mix levels — the boss cues carry the drama; `attack`, `skill`
    /// and especially `buttonTap` fire constantly so they sit well under
    /// everything else.
    private static func volume(for effect: SoundEffect) -> Float {
        switch effect {
        case .bossEncounter: return 1.0
        case .bossVictory: return 0.85
        case .ultimate: return 0.9
        case .levelUp: return 0.8
        case .summon: return 0.7
        case .reward: return 0.6
        case .skill: return 0.5
        case .attack: return 0.32
        case .buttonTap: return 0.25
        default: return 0.8
        }
    }

    private var pools: [SoundEffect: [AVAudioPlayer]] = [:]
    private var sessionReady = false

    private func activateSessionIfNeeded() {
        guard !sessionReady else { return }
        sessionReady = true
        #if canImport(AVFAudio) && !os(macOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            NSLog("[Audio] session activation failed: %@", error.localizedDescription)
        }
        #endif
    }

    /// Returns `true` if it owns playback for this cue (played it, or
    /// deliberately dropped an over-eager re-trigger); `false` if the caller
    /// should use the system-sound fallback.
    func play(_ effect: SoundEffect) -> Bool {
        guard let name = Self.fileName[effect],
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            return false
        }
        activateSessionIfNeeded()

        var pool = pools[effect] ?? []
        let volume = Self.volume(for: effect)

        if let idle = pool.first(where: { !$0.isPlaying }) {
            idle.volume = volume
            idle.currentTime = 0
            idle.play()
            return true
        }
        // All players busy — grow the pool up to a small cap, otherwise just
        // let the in-flight copies ride (better than a jarring restart).
        guard pool.count < 3, let player = try? AVAudioPlayer(contentsOf: url) else {
            return true
        }
        player.volume = volume
        player.prepareToPlay()
        player.play()
        pool.append(player)
        pools[effect] = pool
        return true
    }
}
#endif
