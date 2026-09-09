import Foundation

/// A single regular-encounter species. Pure flavor + a light stat/role tag —
/// `EnemyFactory` keeps all the scaling math, so adding a monster is always
/// just appending a line here, never touching gameplay code.
struct MonsterKind {
    var name: String
    var symbol: String
    var lore: String
    var role: Role = .damage
    var rarity: Rarity = .common
}

/// A unique boss identity for a world's final stage.
struct BossKind {
    var symbol: String
    var ultimate: UltimateSkill
    var mechanic: BossMechanic
    var lore: String
}

/// Per-world regular enemy rosters and unique boss identities, keyed by
/// `World.id`. Pure flavor data — EnemyFactory keeps all the scaling math,
/// and nothing here ever branches on a specific monster's identity.
enum MonsterCatalog {
    private static let regularsByWorld: [Int: [MonsterKind]] = [
        1: [
            MonsterKind(name: "Bramble Stalker", symbol: "leaf.fill", lore: "Creeps through the tall grass, thorns bristling at the first sign of a footstep."),
            MonsterKind(name: "Dust Wisp", symbol: "wind", lore: "A loose knot of drifting pollen and static, harmless until it swarms."),
            MonsterKind(name: "Meadow Sprite", symbol: "ladybug.fill", lore: "Small, quick, and fiercely territorial over its patch of clover."),
            MonsterKind(name: "Sunpetal Guardian", symbol: "sun.max.fill", lore: "Blooms once at dawn and stands watch over the meadow until dusk.")
        ],
        2: [
            MonsterKind(name: "Gloom Hound", symbol: "moon.fill", lore: "Hunts in the space between shadows, never quite where you last saw it."),
            MonsterKind(name: "Hollow Shade", symbol: "theatermask.and.paintbrush.fill", lore: "Wears the shape of a forgotten dream, hollow at the center."),
            MonsterKind(name: "Night Wisp", symbol: "sparkle", lore: "A cold ember of moonlight that flickers whenever it's watched."),
            MonsterKind(name: "Thornback Prowler", symbol: "pawprint.fill", lore: "Silent on the forest floor, its spines the only warning it gives.")
        ],
        3: [
            MonsterKind(name: "Rift Crawler", symbol: "hexagon.fill", lore: "Skitters along cracks in the cavern walls where light doesn't quite reach."),
            MonsterKind(name: "Frost Wisp", symbol: "snowflake", lore: "Breathes out a thin, glittering cold that clings to whatever it touches."),
            MonsterKind(name: "Cavern Serpent", symbol: "tropicalstorm", lore: "Coils through the underground tides, patient and impossibly long."),
            MonsterKind(name: "Crystal Wisp", symbol: "diamond.fill", lore: "Refracts every sound in the cavern into a faint, discordant chime.")
        ],
        // World 4 — Starfall Peaks (Astral)
        4: [
            MonsterKind(name: "Starfang", symbol: "sparkles", lore: "A shard of an old star given teeth, prowling the meteor fields.", role: .damage, rarity: .common),
            MonsterKind(name: "Cometpaw", symbol: "sparkle", lore: "Leaves a trail of dying light with every leap between floating peaks.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Astralwing", symbol: "hexagon.fill", lore: "Circles the star temple ruins on wings woven from old constellations.", role: .support, rarity: .common),
            MonsterKind(name: "Stardustling", symbol: "diamond.fill", lore: "Small and glittering, it scatters into motes when startled.", role: .healer, rarity: .uncommon),
            MonsterKind(name: "Cosmobite", symbol: "sparkles", lore: "Its bite carries a cold, distant chill from beyond the sky.", role: .damage, rarity: .common),
            MonsterKind(name: "Nebulaclaw", symbol: "sparkle", lore: "Claws wreathed in drifting cosmic haze, silent as vacuum.", role: .tank, rarity: .rare),
            MonsterKind(name: "Starhorn", symbol: "hexagon.fill", lore: "Charges the crystal spires of Starfall Peaks head-first.", role: .tank, rarity: .common),
            MonsterKind(name: "Cometscale", symbol: "diamond.fill", lore: "Scales that shed light long after the creature has moved on.", role: .control, rarity: .uncommon)
        ],
        // World 5 — The Forgotten Dream (Lunar)
        5: [
            MonsterKind(name: "Moonfang", symbol: "moon.fill", lore: "Wanders the broken buildings, howling at a moon no one else remembers.", role: .damage, rarity: .common),
            MonsterKind(name: "Duskhorn", symbol: "moon.stars.fill", lore: "Charges out of the dense fog before its silhouette ever resolves.", role: .tank, rarity: .common),
            MonsterKind(name: "Nightclaw", symbol: "theatermask.and.paintbrush.fill", lore: "Claws that leave no mark, only the memory of having been cut.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Shadowtail", symbol: "moon.fill", lore: "Its tail lags a full second behind the rest of its body.", role: .damage, rarity: .common),
            MonsterKind(name: "Eclipsepaw", symbol: "moon.stars.fill", lore: "Steps between floating ruin-fragments as if they were solid ground.", role: .control, rarity: .rare),
            MonsterKind(name: "Dreamstalker", symbol: "theatermask.and.paintbrush.fill", lore: "Follows dreamers through the fog long after they've woken.", role: .support, rarity: .uncommon),
            MonsterKind(name: "Moonscale", symbol: "moon.fill", lore: "Scales that dim and brighten with a moon phase all their own.", role: .tank, rarity: .common),
            MonsterKind(name: "Gloomfang", symbol: "moon.stars.fill", lore: "A last echo of the dream this ruined city used to be.", role: .damage, rarity: .uncommon)
        ],
        // World 6 — Emberheart Wastes (Ember)
        6: [
            MonsterKind(name: "Cinderfang", symbol: "flame.fill", lore: "Prowls the ash fields, jaws glowing faintly with banked heat.", role: .damage, rarity: .common),
            MonsterKind(name: "Ashclaw", symbol: "sun.max.fill", lore: "Leaves smoldering prints across the black volcanic rock.", role: .tank, rarity: .common),
            MonsterKind(name: "Flamehorn", symbol: "bolt.fill", lore: "Charges lava lakes head-on without slowing.", role: .tank, rarity: .uncommon),
            MonsterKind(name: "Scorchling", symbol: "flame.fill", lore: "Small, quick, and always a little too close to catching fire.", role: .damage, rarity: .common),
            MonsterKind(name: "Embermaw", symbol: "sun.max.fill", lore: "Its bite carries the heat of a coal that never quite cools.", role: .damage, rarity: .common),
            MonsterKind(name: "Blazetail", symbol: "bolt.fill", lore: "A whip-crack tail that leaves a line of fire in the ash.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Magmabite", symbol: "flame.fill", lore: "Bites clean through cooled rock crust in search of the wastes' heat.", role: .damage, rarity: .rare),
            MonsterKind(name: "Charhound", symbol: "sun.max.fill", lore: "Hunts in the choking ash clouds by scent alone.", role: .support, rarity: .common),
            MonsterKind(name: "Pyrewing", symbol: "bolt.fill", lore: "Circles the burning ruins on wings of drifting ember.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Inferclaw", symbol: "flame.fill", lore: "Claws still hot from the lava lake it just crawled out of.", role: .damage, rarity: .common),
            MonsterKind(name: "Coalback", symbol: "sun.max.fill", lore: "A ridged spine that glows brighter the angrier it gets.", role: .tank, rarity: .common),
            MonsterKind(name: "Searscale", symbol: "bolt.fill", lore: "Scales that scald anything that gets too close.", role: .damage, rarity: .uncommon),
            MonsterKind(name: "Flarefang", symbol: "flame.fill", lore: "A sudden burst of light and teeth from the ash cloud.", role: .damage, rarity: .common),
            MonsterKind(name: "Burnpaw", symbol: "sun.max.fill", lore: "Leaves scorched pawprints wherever it walks.", role: .support, rarity: .common),
            MonsterKind(name: "Ignisprite", symbol: "bolt.fill", lore: "A tiny fire-spirit born from a stray cinder off Ignivar's own flame.", role: .healer, rarity: .rare),
            MonsterKind(name: "Ashenox", symbol: "flame.fill", lore: "Wears a coat of drifting ash over skin still smoldering beneath.", role: .tank, rarity: .uncommon)
        ],
        // World 7 — Tidal Abyss (Tide)
        7: [
            MonsterKind(name: "Mistfin", symbol: "drop.fill", lore: "Slips through the coral forest wrapped in a veil of cold mist.", role: .damage, rarity: .common),
            MonsterKind(name: "Tideclaw", symbol: "snowflake", lore: "Claws that pull with the force of a rising tide.", role: .tank, rarity: .common),
            MonsterKind(name: "Ripplefang", symbol: "tropicalstorm", lore: "Every bite sends a ring of current rippling outward.", role: .damage, rarity: .uncommon),
            MonsterKind(name: "Aquabite", symbol: "drop.fill", lore: "Small and quick, darting between sunken temple pillars.", role: .damage, rarity: .common),
            MonsterKind(name: "Wavepup", symbol: "snowflake", lore: "Young and playful, riding the abyss's slow deep currents.", role: .support, rarity: .common),
            MonsterKind(name: "Rainscale", symbol: "tropicalstorm", lore: "Scales that weep a constant, cold trickle of seawater.", role: .healer, rarity: .uncommon),
            MonsterKind(name: "Deepfin", symbol: "drop.fill", lore: "Never surfaces — the trench is the only home it has known.", role: .tank, rarity: .rare),
            MonsterKind(name: "Brookling", symbol: "snowflake", lore: "A trickle of a creature that pools into something larger when threatened.", role: .support, rarity: .common),
            MonsterKind(name: "Frostgill", symbol: "tropicalstorm", lore: "Gills that chill the water for a body length in every direction.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Stormfin", symbol: "drop.fill", lore: "Churns the water into a squall wherever it swims.", role: .damage, rarity: .common),
            MonsterKind(name: "Pearlmaw", symbol: "snowflake", lore: "Its jaw glints with a lifetime of swallowed pearls.", role: .damage, rarity: .common),
            MonsterKind(name: "Splashpaw", symbol: "tropicalstorm", lore: "Bounds along the sunken temple floor in bursts of current.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Drownscale", symbol: "drop.fill", lore: "Legend says it once pulled an entire temple beneath the waves.", role: .tank, rarity: .rare),
            MonsterKind(name: "Riverfang", symbol: "snowflake", lore: "Older than the abyss itself, or so the coral forest tells it.", role: .damage, rarity: .common),
            MonsterKind(name: "Mistcrawler", symbol: "tropicalstorm", lore: "Crawls along the trench floor where no light has ever reached.", role: .support, rarity: .common),
            MonsterKind(name: "Abyssfin", symbol: "drop.fill", lore: "The deepest-dwelling of Thalassor's countless subjects.", role: .damage, rarity: .uncommon)
        ],
        // World 8 — Eternal Bloom (Bloom)
        8: [
            MonsterKind(name: "Thornpaw", symbol: "leaf.fill", lore: "Pads silently through root tunnels wider than any road.", role: .damage, rarity: .common),
            MonsterKind(name: "Mossfang", symbol: "ladybug.fill", lore: "So thickly covered in moss it looks like part of the jungle floor.", role: .tank, rarity: .common),
            MonsterKind(name: "Leafling", symbol: "wind", lore: "Small and quick, camouflaged among the oversized canopy.", role: .support, rarity: .common),
            MonsterKind(name: "Rootclaw", symbol: "leaf.fill", lore: "Claws grown from a root that never stopped reaching.", role: .damage, rarity: .uncommon),
            MonsterKind(name: "Vinebeast", symbol: "ladybug.fill", lore: "Trails living vine behind it as it moves through the undergrowth.", role: .tank, rarity: .uncommon),
            MonsterKind(name: "Bloomtail", symbol: "wind", lore: "A flowering tail that opens only when it senses a threat.", role: .control, rarity: .common),
            MonsterKind(name: "Petalhorn", symbol: "leaf.fill", lore: "Charges beneath an oversized, brilliantly colored bloom.", role: .tank, rarity: .common),
            MonsterKind(name: "Barkhide", symbol: "ladybug.fill", lore: "Skin as tough and gnarled as the jungle's oldest trees.", role: .tank, rarity: .rare),
            MonsterKind(name: "Sporeling", symbol: "wind", lore: "Releases a faint cloud of spores whenever it's startled.", role: .healer, rarity: .uncommon),
            MonsterKind(name: "Wildthorn", symbol: "leaf.fill", lore: "A tangle of thorn and muscle native only to Eternal Bloom.", role: .damage, rarity: .common),
            MonsterKind(name: "Fernfang", symbol: "ladybug.fill", lore: "Bites through the thick canopy vines with practiced ease.", role: .damage, rarity: .common),
            MonsterKind(name: "Brambleback", symbol: "wind", lore: "A spine of interlocking brambles no predator wants to test.", role: .tank, rarity: .uncommon),
            MonsterKind(name: "Rootmaw", symbol: "leaf.fill", lore: "Waits beneath the tunnel floor for something to walk overhead.", role: .damage, rarity: .rare),
            MonsterKind(name: "Seedling Beast", symbol: "ladybug.fill", lore: "Young, but already larger than most fully grown Bloom creatures.", role: .support, rarity: .common),
            MonsterKind(name: "Ivyclaw", symbol: "wind", lore: "Ivy grows over its claws between meals, then sheds when it hunts.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Thornbloom", symbol: "leaf.fill", lore: "The jungle's oldest bloom given claws, close kin to Verdantor.", role: .damage, rarity: .uncommon)
        ],
        // World 9 — Realm of Eclipse (Lunar)
        9: [
            MonsterKind(name: "Nightshade", symbol: "theatermask.and.paintbrush.fill", lore: "Grows only where Noctyra's permanent eclipse falls darkest.", role: .damage, rarity: .common),
            MonsterKind(name: "Lunawing", symbol: "moon.fill", lore: "Circles the watching moon on wings that never cast a shadow.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Darkpelt", symbol: "moon.stars.fill", lore: "A coat so black it swallows the eclipse's faint light entirely.", role: .tank, rarity: .common),
            MonsterKind(name: "Crescentclaw", symbol: "theatermask.and.paintbrush.fill", lore: "Claws curved like the sliver of moon this realm never quite sees.", role: .damage, rarity: .rare),
            MonsterKind(name: "Voidpaw", symbol: "moon.fill", lore: "Steps leave no print — the eclipse realm forgets it was ever there.", role: .control, rarity: .uncommon),
            MonsterKind(name: "Duskscale", symbol: "moon.stars.fill", lore: "Scales caught permanently between day and night.", role: .tank, rarity: .common),
            MonsterKind(name: "Nightmare Beast", symbol: "theatermask.and.paintbrush.fill", lore: "One of Noctyra's own court, given form from the realm's endless dark.", role: .damage, rarity: .rare)
        ],
        // World 10 — Celestial Dream (Astral)
        10: [
            MonsterKind(name: "Galaxipaw", symbol: "sparkles", lore: "Each pawprint briefly holds a swirl of tiny stars.", role: .damage, rarity: .uncommon),
            MonsterKind(name: "Meteorfang", symbol: "sparkle", lore: "Fell to the cosmic islands still burning at the edges.", role: .damage, rarity: .rare),
            MonsterKind(name: "Celestling", symbol: "hexagon.fill", lore: "Small, but drawn from the same light as Elyndor itself.", role: .support, rarity: .uncommon),
            MonsterKind(name: "Voidstar", symbol: "diamond.fill", lore: "A star gone dark, still pulling everything nearby toward it.", role: .control, rarity: .rare),
            MonsterKind(name: "Nebulabeast", symbol: "sparkles", lore: "Drifts between the starlit temples wrapped in cosmic haze.", role: .tank, rarity: .uncommon),
            MonsterKind(name: "Starlight Claw", symbol: "sparkle", lore: "Claws that glow with borrowed light from a galaxy long gone.", role: .damage, rarity: .rare),
            MonsterKind(name: "Astralmaw", symbol: "hexagon.fill", lore: "Guards the center of the Dream realm alongside its sovereign.", role: .tank, rarity: .legendary)
        ]
    ]

    private static let bossesByWorld: [Int: BossKind] = [
        1: BossKind(symbol: "flame.fill", ultimate: UltimateSkill(
            name: "Unraveling Bloom", description: "The meadow itself lashes out in bloom and fire.",
            damageMultiplier: 1.8, attacksToCharge: 4
        ), mechanic: .selfHeal, lore: "Once the meadow's oldest bloom, now unraveling into thorn and flame with every dream it consumes."),
        2: BossKind(symbol: "moon.stars.fill", ultimate: UltimateSkill(
            name: "Nightmare Grasp", description: "Shadows claw in from every direction at once.",
            damageMultiplier: 2.0, attacksToCharge: 4
        ), mechanic: .enrage, lore: "Keeper of the forest's deepest gloom, it grows more furious the closer it comes to falling."),
        3: BossKind(symbol: "diamond.fill", ultimate: UltimateSkill(
            name: "Sentinel's Judgment", description: "A crushing wave of crystallized force.",
            damageMultiplier: 1.9, attacksToCharge: 5
        ), mechanic: .shield, lore: "A living crystal grown around a dream too heavy to wake from, shielded on every side."),
        4: BossKind(symbol: "star.fill", ultimate: UltimateSkill(
            name: "Starfall Cataclysm", description: "A meteor storm crashes down from the shattered sky.",
            damageMultiplier: 1.9, attacksToCharge: 5
        ), mechanic: .shield, lore: "A star that fell from the heavens eons ago, still burning with the light of its old sky."),
        5: BossKind(symbol: "moon.stars.fill", ultimate: UltimateSkill(
            name: "Nightmare Feast", description: "Consumes the last of its prey's waking thoughts.",
            damageMultiplier: 1.85, attacksToCharge: 4
        ), mechanic: .drain, lore: "An ancient thing that feeds on forgotten dreams, growing fatter with every one it swallows."),
        6: BossKind(symbol: "flame.fill", ultimate: UltimateSkill(
            name: "Ashfall Reckoning", description: "A tidal wave of molten rock and cinder.",
            damageMultiplier: 2.0, attacksToCharge: 4
        ), mechanic: .enrage, lore: "A titan of fire that slept beneath the wastes for a thousand years, now awake and furious."),
        7: BossKind(symbol: "tropicalstorm", ultimate: UltimateSkill(
            name: "Abyssal Tide", description: "A crushing wave from the deepest trench.",
            damageMultiplier: 1.85, attacksToCharge: 4
        ), mechanic: .selfHeal, lore: "Ruler of the deepest trench in the Tidal Abyss, its court are things that never see the surface."),
        8: BossKind(symbol: "leaf.fill", ultimate: UltimateSkill(
            name: "Rootbound Judgment", description: "The forest floor erupts in thorn and vine.",
            damageMultiplier: 1.9, attacksToCharge: 5
        ), mechanic: .regenShield, lore: "A root older than the forest itself, slumbering beneath Eternal Bloom since before memory."),
        9: BossKind(symbol: "moon.fill", ultimate: UltimateSkill(
            name: "Eclipse Reign", description: "Shadow and light strike as one.",
            damageMultiplier: 2.0, attacksToCharge: 4
        ), mechanic: .phaseShift, lore: "Sovereign of the permanent eclipse, she rules the realm equally in shadow and stolen light."),
        10: BossKind(symbol: "sparkles", ultimate: UltimateSkill(
            name: "Sovereign's Dominion", description: "Every star in the sky answers its call at once.",
            damageMultiplier: 2.2, attacksToCharge: 5
        ), mechanic: .sovereign, lore: "Ruler of the highest dream, and the last, greatest guardian the Dreamkeepers must face.")
    ]

    /// Worlds 11-30 are a second and third "dreaming" of worlds 1-10 — same
    /// monsters and boss identity, far stronger stats (`World.difficultyMultiplier`)
    /// — rather than 20 more hand-authored rosters. Any world beyond the
    /// original 10 maps back to whichever of the first 10 it echoes.
    private static func sourceWorldID(for worldID: Int) -> Int {
        guard worldID > 10 else { return worldID }
        return ((worldID - 1) % 10) + 1
    }

    static func regularMonster(forWorld worldID: Int, stage: Int) -> MonsterKind {
        let list = regularsByWorld[sourceWorldID(for: worldID)] ?? regularsByWorld[1]!
        return list[stage % list.count]
    }

    static func boss(forWorld worldID: Int) -> BossKind {
        bossesByWorld[sourceWorldID(for: worldID)] ?? bossesByWorld[1]!
    }

    /// All monster kinds for a world (regulars first, boss last) — the
    /// Bestiary's source of truth for what a world's codex page contains.
    static func allEntries(forWorld worldID: Int) -> [(name: String, symbol: String, lore: String, isBoss: Bool, rarity: Rarity)] {
        let sourceID = sourceWorldID(for: worldID)
        let regulars = (regularsByWorld[sourceID] ?? []).map { (name: $0.name, symbol: $0.symbol, lore: $0.lore, isBoss: false, rarity: $0.rarity) }
        let world = WorldCatalog.worlds.first { $0.id == worldID }
        let boss = bossesByWorld[sourceID]
        let bossEntry = boss.map { (name: world?.bossName ?? "Boss", symbol: $0.symbol, lore: $0.lore, isBoss: true, rarity: Rarity.legendary) }
        return regulars + (bossEntry.map { [$0] } ?? [])
    }

    /// Prefix + suffix combinator so future content updates can generate
    /// more monsters purely from data, without touching gameplay code (spec
    /// section 4: "System soll später automatisch weitere Monster erzeugen
    /// können"). Not used by the shipped roster above, which is hand-picked
    /// for lore quality — this is the growth path beyond it.
    enum NameGenerator {
        static let prefixesByElement: [Element: [String]] = [
            .ember: ["Ember", "Cinder", "Ash", "Blaze", "Flare", "Scorch", "Magma", "Char", "Pyre", "Infer", "Coal", "Sear", "Burn", "Ignis"],
            .tide: ["Tide", "Mist", "Ripple", "Aqua", "Wave", "Rain", "Deep", "Brook", "Frost", "Storm", "Pearl", "Splash", "Drown", "River", "Abyss"],
            .bloom: ["Thorn", "Moss", "Leaf", "Root", "Vine", "Bloom", "Petal", "Bark", "Spore", "Wild", "Fern", "Bramble", "Ivy"],
            .lunar: ["Moon", "Dusk", "Night", "Shadow", "Eclipse", "Dream", "Gloom", "Luna", "Dark", "Crescent", "Void"],
            .astral: ["Star", "Comet", "Astral", "Stardust", "Cosmo", "Nebula", "Galaxi", "Meteor", "Celest", "Void"]
        ]
        static let suffixes = [
            "fang", "claw", "paw", "horn", "tail", "wing", "scale", "maw", "back", "hide",
            "pelt", "beast", "ling", "crawler", "stalker", "prowler", "wisp", "sprite"
        ]

        /// Deterministic given the same `seed`, so a content pipeline can
        /// dedupe and re-run without producing a different name each time.
        static func generate(element: Element, seed: Int) -> String {
            let prefixes = prefixesByElement[element] ?? ["Dream"]
            let prefix = prefixes[seed % prefixes.count]
            let suffix = suffixes[(seed / max(prefixes.count, 1)) % suffixes.count]
            return prefix + suffix
        }
    }
}
