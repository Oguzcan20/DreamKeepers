import Foundation

/// Combat stats. `energyGain` controls how fast the ultimate charges per basic attack.
struct Stats: Codable, Equatable {
    var hp: Double
    var attack: Double
    var defense: Double
    var speed: Double

    static let zero = Stats(hp: 0, attack: 0, defense: 0, speed: 0)

    static func + (lhs: Stats, rhs: Stats) -> Stats {
        Stats(hp: lhs.hp + rhs.hp, attack: lhs.attack + rhs.attack,
              defense: lhs.defense + rhs.defense, speed: lhs.speed + rhs.speed)
    }

    static func * (lhs: Stats, factor: Double) -> Stats {
        Stats(hp: lhs.hp * factor, attack: lhs.attack * factor,
              defense: lhs.defense * factor, speed: lhs.speed * factor)
    }

    var rounded: Stats {
        Stats(hp: hp.rounded(), attack: attack.rounded(),
              defense: defense.rounded(), speed: speed.rounded())
    }
}
