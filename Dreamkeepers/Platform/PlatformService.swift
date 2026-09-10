import Foundation

enum HapticStyle {
    case light, success, warning, levelUp
}

/// UI/gameplay sound cues (spec: Button Click, Level Up, Loot, Summon, Skill,
/// Ultimate, Boss, Reward). The battle cues (`attack`, `skill`, `ultimate`,
/// `bossEncounter`, `bossVictory`) are backed by real composed audio files
/// bundled in `Resources/Audio/` (see `synth_battle_audio.py` — a procedural
/// synth, no third-party samples): `attack`/`skill` are deliberately tiny
/// and quiet (they fire on every hit / skill tap), the boss cues are short
/// dramatic stings. Everything else still renders via built-in iOS system
/// sound IDs. A missing/undecodable audio file transparently falls back to
/// the system-sound path, so call sites never need to care which backend
/// played.
enum SoundEffect {
    case buttonTap, levelUp, loot, summon, attack, skill, ultimate, bossEncounter, bossVictory, reward
}

extension HapticStyle {
    /// Lets `GameState.playHaptic` fire a matching sound automatically at
    /// every existing haptic call site, instead of doubling up every call
    /// site by hand. `.warning` (battle defeat) stays silent on purpose —
    /// a defeat doesn't need a chime.
    var pairedSoundEffect: SoundEffect? {
        switch self {
        case .light: return .buttonTap
        case .success: return .reward
        case .warning: return nil
        case .levelUp: return .levelUp
        }
    }
}

/// Everything game/UI code needs from the host OS, behind one seam. iOS is the
/// only implementation built and tested today (spec: iOS-first); an
/// AndroidPlatformService can be added later without touching call sites.
///
///     PlatformService
///      ├── iOSPlatformService   (active)
///      └── AndroidPlatformService  (future)
protocol PlatformService {
    /// Directory the save system should write into.
    var appStorageDirectory: URL { get }
    func playHaptic(_ style: HapticStyle)
    func playSound(_ effect: SoundEffect)

    /// Asks the OS for local-notification permission if the player hasn't
    /// been asked before; calls back `false` without prompting if already
    /// denied. `completion` always runs on the main thread.
    func requestNotificationAuthorization(completion: @escaping (Bool) -> Void)
    /// Schedules (replacing any pending request with the same `id`) a
    /// one-shot local notification for `fireDate`. Does nothing if
    /// `fireDate` is already in the past.
    func scheduleNotification(id: String, title: String, body: String, fireDate: Date)
    /// Schedules a local notification that repeats every day at `hour:minute`
    /// in the device's current calendar/time zone.
    func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int)
    func cancelNotification(id: String)
    func cancelAllNotifications()
}
