import Foundation

enum MissionID: String, CaseIterable, Codable {
    case winBattle
    case performSummon
    case collectBuilding
    case upgradeEquipment
    case spendInShop
    case defeatBoss
    case deployFullTeam
    case premiumBonusStages
    case premiumBonusSummons
}

struct MissionDefinition: Identifiable {
    var id: MissionID
    var title: String
    var icon: String
    var target: Int
    var goldReward: Int
    var gemReward: Int
    /// Energy granted on claim — a small comeback source so a stamina-empty
    /// player still has a free way back in besides waiting or spending gems.
    var energyReward: Int = 0
    /// Battle Pass Premium-exclusive bonus mission — tracked like any other
    /// daily mission, but only claimable (and only shown as available,
    /// rather than locked) once Premium is unlocked.
    var isPremiumOnly: Bool = false
    /// Free Dreamkeeper Summoning ticket granted on claim — see
    /// `GameSave.monsterSummonTickets`. Only `.defeatBoss` grants one today.
    var monsterTicketReward: Int = 0
    /// Free Equipment Summoning ticket granted on claim — see
    /// `GameSave.equipmentSummonTickets`. Only `.upgradeEquipment` grants
    /// one today.
    var equipmentTicketReward: Int = 0
}

/// Quest pool. Progress and claims live on `GameSave`, keyed by
/// `MissionID.rawValue`, and reset once the stored day no longer matches
/// today (see `GameState.ensureMissionsCurrent`). The 7 free-tier missions
/// are a rotation pool, not a fixed daily set — each day draws `activeCount`
/// of them at random (see `drawDaily`) so the board isn't identical every
/// day. Premium bonus missions aren't part of the rotation; they're always
/// shown (locked until Premium is unlocked), same as before.
enum DailyMissions {
    /// How many of the 7 free-tier missions are active on a given day.
    static let activeCount = 4

    static let definitions: [MissionDefinition] = [
        MissionDefinition(id: .winBattle, title: "Clear a Stage", icon: "flag.checkered",
                           target: 1, goldReward: 40, gemReward: 0, energyReward: 10),
        MissionDefinition(id: .performSummon, title: "Summon a Dreamkeeper", icon: "sparkles",
                           target: 1, goldReward: 0, gemReward: 5),
        MissionDefinition(id: .collectBuilding, title: "Collect from a Building", icon: "hand.tap.fill",
                           target: 1, goldReward: 30, gemReward: 0),
        MissionDefinition(id: .upgradeEquipment, title: "Upgrade a Piece of Gear", icon: "hammer.fill",
                           target: 1, goldReward: 0, gemReward: 6, equipmentTicketReward: 1),
        MissionDefinition(id: .spendInShop, title: "Visit the Shop", icon: "cart.fill",
                           target: 1, goldReward: 25, gemReward: 0),
        MissionDefinition(id: .defeatBoss, title: "Defeat a Boss", icon: "flame.fill",
                           target: 1, goldReward: 0, gemReward: 10, energyReward: 15, monsterTicketReward: 1),
        MissionDefinition(id: .deployFullTeam, title: "Field a Full Team", icon: "person.3.fill",
                           target: 1, goldReward: 20, gemReward: 0),
        MissionDefinition(id: .premiumBonusStages, title: "Clear 3 Stages", icon: "flag.2.crossed.fill",
                           target: 3, goldReward: 80, gemReward: 8, energyReward: 20, isPremiumOnly: true),
        MissionDefinition(id: .premiumBonusSummons, title: "Summon 3 Dreamkeepers", icon: "wand.and.stars",
                           target: 3, goldReward: 0, gemReward: 15, isPremiumOnly: true)
    ]

    /// The free-tier rotation pool — every mission that isn't a Premium
    /// bonus. Exactly 7 today; `drawDaily` picks `activeCount` of these.
    static let rotatingPool: [MissionID] = definitions.filter { !$0.isPremiumOnly }.map(\.id)

    /// Picks today's active free-tier missions at random. Called once per
    /// calendar day from `GameState.ensureMissionsCurrent`, which persists
    /// the result — this itself is stateless so the same day never has to
    /// re-derive a matching draw from a seed.
    static func drawDaily() -> [String] {
        Array(rotatingPool.shuffled().prefix(activeCount)).map(\.rawValue)
    }
}
