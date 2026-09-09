import SwiftUI

enum Element: String, Codable, CaseIterable, Identifiable {
    case ember, tide, bloom, lunar, astral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ember: return "Ember"
        case .tide: return "Tide"
        case .bloom: return "Bloom"
        case .lunar: return "Lunar"
        case .astral: return "Astral"
        }
    }

    var symbol: String {
        switch self {
        case .ember: return "flame.fill"
        case .tide: return "drop.fill"
        case .bloom: return "leaf.fill"
        case .lunar: return "moon.stars.fill"
        case .astral: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .ember: return Color(red: 0.95, green: 0.42, blue: 0.32)
        case .tide: return Color(red: 0.32, green: 0.62, blue: 0.95)
        case .bloom: return Color(red: 0.45, green: 0.78, blue: 0.4)
        case .lunar: return Color(red: 0.65, green: 0.6, blue: 0.95)
        case .astral: return Color(red: 0.87, green: 0.75, blue: 0.35)
        }
    }

    /// Returns the damage multiplier this element deals against `other`.
    func multiplier(against other: Element) -> Double {
        let advantage: [Element: Element] = [
            .ember: .bloom,
            .bloom: .tide,
            .tide: .ember
        ]
        if advantage[self] == other { return 1.25 }
        if advantage[other] == self { return 0.8 }
        return 1.0
    }
}
