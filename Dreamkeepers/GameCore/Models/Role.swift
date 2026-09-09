import SwiftUI

enum Role: String, Codable, CaseIterable, Identifiable {
    case tank, damage, support, healer, control
    /// Tank/Support hybrid: Ultimate shields the whole team, Active Skill
    /// strikes and slows the enemy. See `BattleEngine.shieldAllies` /
    /// `quickStrikeAndSlow`. Introduced for Igo rather than special-casing
    /// his identity in combat code.
    case guardian

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tank: return "Tank"
        case .damage: return "Damage"
        case .support: return "Support"
        case .healer: return "Healer"
        case .control: return "Control"
        case .guardian: return "Guardian"
        }
    }

    var symbol: String {
        switch self {
        case .tank: return "shield.fill"
        case .damage: return "bolt.fill"
        case .support: return "wand.and.stars"
        case .healer: return "cross.case.fill"
        case .control: return "snowflake"
        case .guardian: return "shield.righthalf.filled"
        }
    }
}
