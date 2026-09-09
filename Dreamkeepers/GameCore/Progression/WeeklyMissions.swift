import Foundation

enum WeeklyMissionID: String, CaseIterable, Codable {
    case clearStages
    case defeatBosses
    case performSummons
    case upgradeEquipment
    case visitShop
}

struct WeeklyMissionDefinition: Identifiable {
    var id: WeeklyMissionID
    var title: String
    var icon: String
    var target: Int
    var goldReward: Int
    var gemReward: Int
    var energyReward: Int = 0
}

/// Battle Pass Premium-exclusive weekly quest set — harder targets than the
/// daily missions, bigger reward, resets on a calendar-week boundary (see
/// `GameState.ensureWeeklyMissionsCurrent`). Progress accrues for every
/// player the same way daily missions do; only claiming is gated behind
/// Premium, so nothing is lost by unlocking mid-week.
enum WeeklyMissions {
    static let definitions: [WeeklyMissionDefinition] = [
        WeeklyMissionDefinition(id: .clearStages, title: "Clear 15 Stages", icon: "flag.2.crossed.fill",
                                 target: 15, goldReward: 300, gemReward: 20, energyReward: 40),
        WeeklyMissionDefinition(id: .defeatBosses, title: "Defeat 5 Bosses", icon: "flame.fill",
                                 target: 5, goldReward: 0, gemReward: 30, energyReward: 30),
        WeeklyMissionDefinition(id: .performSummons, title: "Summon 5 Dreamkeepers", icon: "wand.and.stars",
                                 target: 5, goldReward: 0, gemReward: 25),
        WeeklyMissionDefinition(id: .upgradeEquipment, title: "Upgrade Gear 8 Times", icon: "hammer.fill",
                                 target: 8, goldReward: 200, gemReward: 0),
        WeeklyMissionDefinition(id: .visitShop, title: "Visit the Shop 3 Times", icon: "cart.fill",
                                 target: 3, goldReward: 0, gemReward: 15)
    ]
}
