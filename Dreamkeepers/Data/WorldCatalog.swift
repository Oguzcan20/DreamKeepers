import SwiftUI

/// The full campaign: 30 worlds x 5 stages = 150 stages. Worlds 11-30 are a
/// second and third "dreaming" of worlds 1-10 — same monster rosters (see
/// `MonsterCatalog.sourceWorldID(for:)`), scaled far stronger via
/// `difficultyMultiplier`. Difficulty climbs in felt tiers, not just smooth
/// linear growth — see `World.difficultyMultiplier` and `EnemyFactory`.
enum WorldCatalog {
    static let worlds: [World] = [
        World(
            id: 1,
            name: "Whispering Meadow",
            description: "A quiet, sunlit field where the first dreams take root.",
            accentColor: Color(red: 0.45, green: 0.78, blue: 0.4),
            elementBias: [.bloom, .ember],
            bossName: "The Unraveling"
        ),
        World(
            id: 2,
            name: "Moonlit Forest",
            description: "A dark wood lit only by luminous, dreaming flora.",
            accentColor: Color(red: 0.55, green: 0.5, blue: 0.85),
            elementBias: [.lunar, .astral],
            bossName: "Nightmare Warden"
        ),
        World(
            id: 3,
            name: "Crystal Caverns",
            description: "Frozen tides given form beneath the waking world.",
            accentColor: Color(red: 0.35, green: 0.65, blue: 0.9),
            elementBias: [.tide, .astral],
            bossName: "Crystal Sentinel"
        ),
        World(
            id: 4,
            name: "Starfall Peaks",
            description: "Floating mountains and meteor fields around an ancient star temple.",
            accentColor: Color(red: 0.75, green: 0.68, blue: 0.95),
            elementBias: [.astral],
            bossName: "Aetherion, the Fallen Star",
            difficultyMultiplier: 1.15
        ),
        World(
            id: 5,
            name: "The Forgotten Dream",
            description: "Broken buildings and floating ruins lost in a surreal, dense fog.",
            accentColor: Color(red: 0.5, green: 0.48, blue: 0.62),
            elementBias: [.lunar],
            bossName: "Morvane, Dream Eater",
            difficultyMultiplier: 1.15
        ),
        World(
            id: 6,
            name: "Emberheart Wastes",
            description: "Vast volcanoes and lakes of lava beneath a sky choked with ash.",
            accentColor: Color(red: 0.85, green: 0.32, blue: 0.2),
            elementBias: [.ember],
            bossName: "Ignivar, Lord of Ash",
            difficultyMultiplier: 1.35
        ),
        World(
            id: 7,
            name: "Tidal Abyss",
            description: "Sunken temples and coral forests deep in a trench no light reaches.",
            accentColor: Color(red: 0.15, green: 0.45, blue: 0.55),
            elementBias: [.tide],
            bossName: "Thalassor, Abyssal King",
            difficultyMultiplier: 1.35
        ),
        World(
            id: 8,
            name: "Eternal Bloom",
            description: "A colossal magical jungle of root tunnels and glowing, oversized flora.",
            accentColor: Color(red: 0.3, green: 0.7, blue: 0.35),
            elementBias: [.bloom],
            bossName: "Verdantor, Ancient Root",
            difficultyMultiplier: 1.55
        ),
        World(
            id: 9,
            name: "Realm of Eclipse",
            description: "A land locked in permanent eclipse beneath a vast, watching moon.",
            accentColor: Color(red: 0.28, green: 0.22, blue: 0.4),
            elementBias: [.lunar],
            bossName: "Noctyra, Queen of Night",
            difficultyMultiplier: 1.8
        ),
        World(
            id: 10,
            name: "Celestial Dream",
            description: "Cosmic islands and starlit temples at the very center of the Dream realm.",
            accentColor: Color(red: 0.95, green: 0.85, blue: 0.55),
            elementBias: [.astral],
            bossName: "Elyndor, The Dream Sovereign",
            difficultyMultiplier: 2.1
        ),

        // MARK: - Second dreaming (worlds 11-20): same rosters, far stronger.

        World(
            id: 11,
            name: "Echoing Meadow",
            description: "The Whispering Meadow dreams itself again — the same creatures returned, grown feral and strong.",
            accentColor: Color(red: 0.37, green: 0.64, blue: 0.33),
            elementBias: [.bloom, .ember],
            bossName: "The Unraveling, Awakened",
            difficultyMultiplier: 2.2
        ),
        World(
            id: 12,
            name: "Shadowed Forest",
            description: "A darker echo of the Moonlit Forest, where old nightmares have grown teeth.",
            accentColor: Color(red: 0.45, green: 0.41, blue: 0.70),
            elementBias: [.lunar, .astral],
            bossName: "Nightmare Warden, Reborn",
            difficultyMultiplier: 2.2
        ),
        World(
            id: 13,
            name: "Deep Crystal Caverns",
            description: "The Crystal Caverns run deeper now, and the cold within has sharpened.",
            accentColor: Color(red: 0.29, green: 0.53, blue: 0.74),
            elementBias: [.tide, .astral],
            bossName: "Crystal Sentinel, Unbroken",
            difficultyMultiplier: 2.3
        ),
        World(
            id: 14,
            name: "Starfall Reignited",
            description: "The meteor fields of Starfall Peaks blaze again, brighter and far more dangerous.",
            accentColor: Color(red: 0.62, green: 0.56, blue: 0.78),
            elementBias: [.astral],
            bossName: "Aetherion, the Star Undying",
            difficultyMultiplier: 2.3
        ),
        World(
            id: 15,
            name: "Dream Beyond Forgetting",
            description: "The Forgotten Dream loops back on itself, its fog thicker than before.",
            accentColor: Color(red: 0.41, green: 0.39, blue: 0.51),
            elementBias: [.lunar],
            bossName: "Morvane, the Endless Hunger",
            difficultyMultiplier: 2.4
        ),
        World(
            id: 16,
            name: "Emberheart Inferno",
            description: "The wastes burn hotter still, and the ash titans return renewed.",
            accentColor: Color(red: 0.70, green: 0.26, blue: 0.16),
            elementBias: [.ember],
            bossName: "Ignivar, Lord of the Deep Ash",
            difficultyMultiplier: 2.4
        ),
        World(
            id: 17,
            name: "The Abyss Unbound",
            description: "The Tidal Abyss opens wider, and its oldest depths stir once more.",
            accentColor: Color(red: 0.12, green: 0.37, blue: 0.45),
            elementBias: [.tide],
            bossName: "Thalassor, the Endless Tide",
            difficultyMultiplier: 2.5
        ),
        World(
            id: 18,
            name: "Bloom Everlasting",
            description: "Eternal Bloom grows without end, its roots stronger than any dreamer remembers.",
            accentColor: Color(red: 0.25, green: 0.57, blue: 0.29),
            elementBias: [.bloom],
            bossName: "Verdantor, the Root Eternal",
            difficultyMultiplier: 2.6
        ),
        World(
            id: 19,
            name: "Eclipse Undying",
            description: "The Realm of Eclipse falls dark again, and its court has grown far more fierce.",
            accentColor: Color(red: 0.23, green: 0.18, blue: 0.33),
            elementBias: [.lunar],
            bossName: "Noctyra, the Endless Night",
            difficultyMultiplier: 2.7
        ),
        World(
            id: 20,
            name: "Celestial Requiem",
            description: "The Celestial Dream sings once more, its cosmic guardians returned in greater strength.",
            accentColor: Color(red: 0.78, green: 0.70, blue: 0.45),
            elementBias: [.astral],
            bossName: "Elyndor, the Last Sovereign",
            difficultyMultiplier: 2.8
        ),

        // MARK: - Third dreaming (worlds 21-30): same rosters, strongest yet.

        World(
            id: 21,
            name: "Meadow's Final Dream",
            description: "A third dreaming of the meadow, wilder and far harder to wake from.",
            accentColor: Color(red: 0.29, green: 0.50, blue: 0.26),
            elementBias: [.bloom, .ember],
            bossName: "The Unraveling, Eternal",
            difficultyMultiplier: 2.85
        ),
        World(
            id: 22,
            name: "The Last Moonlit Forest",
            description: "The forest dreams a final time, its shadows deeper than any before.",
            accentColor: Color(red: 0.35, green: 0.32, blue: 0.54),
            elementBias: [.lunar, .astral],
            bossName: "Nightmare Warden, Undying",
            difficultyMultiplier: 2.9
        ),
        World(
            id: 23,
            name: "Caverns of Endless Crystal",
            description: "The caverns crystallize further still, hardening into something almost eternal.",
            accentColor: Color(red: 0.22, green: 0.42, blue: 0.58),
            elementBias: [.tide, .astral],
            bossName: "Crystal Sentinel, Absolute",
            difficultyMultiplier: 2.9
        ),
        World(
            id: 24,
            name: "Starfall's End",
            description: "The star temple's final fall, brighter and more violent than the sky can hold.",
            accentColor: Color(red: 0.48, green: 0.44, blue: 0.61),
            elementBias: [.astral],
            bossName: "Aetherion, the Fallen Sun",
            difficultyMultiplier: 3.0
        ),
        World(
            id: 25,
            name: "The Dream That Never Wakes",
            description: "The Forgotten Dream folds in on itself one last time, and nothing wakes from it easily.",
            accentColor: Color(red: 0.32, green: 0.31, blue: 0.40),
            elementBias: [.lunar],
            bossName: "Morvane, the Final Hunger",
            difficultyMultiplier: 3.0
        ),
        World(
            id: 26,
            name: "Emberheart's Last Fire",
            description: "The wastes' final blaze, hot enough to reshape the ash fields entirely.",
            accentColor: Color(red: 0.54, green: 0.20, blue: 0.13),
            elementBias: [.ember],
            bossName: "Ignivar, the Last Ember",
            difficultyMultiplier: 3.1
        ),
        World(
            id: 27,
            name: "The Abyss Eternal",
            description: "The trench has no bottom left to find, and what lives there has waited a long time.",
            accentColor: Color(red: 0.10, green: 0.29, blue: 0.35),
            elementBias: [.tide],
            bossName: "Thalassor, Sovereign of the Deep",
            difficultyMultiplier: 3.1
        ),
        World(
            id: 28,
            name: "The Bloom That Never Fades",
            description: "Eternal Bloom reaches its final, endless growth.",
            accentColor: Color(red: 0.19, green: 0.45, blue: 0.22),
            elementBias: [.bloom],
            bossName: "Verdantor, the World Tree's Heart",
            difficultyMultiplier: 3.2
        ),
        World(
            id: 29,
            name: "The Eclipse Absolute",
            description: "Darkness reaches its final form, and its ruler has never been stronger.",
            accentColor: Color(red: 0.18, green: 0.14, blue: 0.26),
            elementBias: [.lunar],
            bossName: "Noctyra, Empress of Shadow",
            difficultyMultiplier: 3.2
        ),
        World(
            id: 30,
            name: "The Final Dream",
            description: "The last dream the Dreamkeepers will ever need to wake from.",
            accentColor: Color(red: 0.61, green: 0.54, blue: 0.35),
            elementBias: [.astral],
            bossName: "Elyndor, the Dreaming God",
            difficultyMultiplier: 3.3
        )
    ]

    static let totalStages = worlds.count * World.stagesPerWorld

    static func world(forStage stage: Int) -> World {
        worlds.first { $0.stages.contains(stage) } ?? worlds.last!
    }
}
