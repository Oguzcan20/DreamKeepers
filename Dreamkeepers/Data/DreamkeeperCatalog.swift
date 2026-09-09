import Foundation

/// Read-only content catalog. Adding a Dreamkeeper means appending one
/// `DreamkeeperDefinition` here — nothing in GameCore/Combat or the UI needs
/// to change.
struct DreamkeeperCatalog {
    let definitions: [DreamkeeperDefinition]
    private let byID: [String: DreamkeeperDefinition]

    init(definitions: [DreamkeeperDefinition]) {
        self.definitions = definitions
        self.byID = Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) })
    }

    func definition(for id: String) -> DreamkeeperDefinition? {
        byID[id]
    }

    static let starter = DreamkeeperCatalog(definitions: [
        DreamkeeperDefinition(
            id: "ember_fox",
            name: "Ember Fox",
            element: .ember,
            role: .damage,
            rarity: .rare,
            baseStats: Stats(hp: 90, attack: 16, defense: 6, speed: 52),
            growthPerLevel: Stats(hp: 7, attack: 1.4, defense: 0.4, speed: 0.5),
            ultimate: UltimateSkill(name: "Wildfire Pounce", description: "A blazing leap that scorches the target.", damageMultiplier: 2.2, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Ember Nip", description: "A quick, scorching nip at the nearest foe.", effectMultiplier: 1.3, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Kindled Spirit", description: "Slightly bolder in a fight.", statBonus: Stats(hp: 0, attack: 2, defense: 0, speed: 0)),
            symbol: "hare.fill",
            flavorText: "Born from a candle's last flicker before dawn."
        ),
        DreamkeeperDefinition(
            id: "moon_hare",
            name: "Moon Hare",
            element: .lunar,
            role: .healer,
            rarity: .rare,
            baseStats: Stats(hp: 100, attack: 10, defense: 7, speed: 48),
            growthPerLevel: Stats(hp: 8, attack: 0.8, defense: 0.5, speed: 0.4),
            ultimate: UltimateSkill(name: "Moonlit Blessing", description: "Bathes the whole team in restorative moonlight.", damageMultiplier: 2.6, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Soothing Touch", description: "A gentle pulse of moonlight for the ally who needs it most.", effectMultiplier: 1.2, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Gentle Glow", description: "A quiet, steadying presence.", statBonus: Stats(hp: 6, attack: 0, defense: 0, speed: 0)),
            symbol: "moon.stars.fill",
            flavorText: "Follows travelers who fall asleep beneath the open sky."
        ),
        DreamkeeperDefinition(
            id: "forest_spirit",
            name: "Forest Spirit",
            element: .bloom,
            role: .support,
            rarity: .uncommon,
            baseStats: Stats(hp: 95, attack: 12, defense: 8, speed: 44),
            growthPerLevel: Stats(hp: 7.5, attack: 1.0, defense: 0.5, speed: 0.35),
            ultimate: UltimateSkill(name: "Verdant Chorus", description: "Rallies the team with a surge of vitality.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Bramble Ward", description: "Wraps itself in hardy brambles, growing bolder.", effectMultiplier: 1.3, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Rooted Calm", description: "Steady footing, steady mind.", statBonus: Stats(hp: 0, attack: 0, defense: 2, speed: 0)),
            symbol: "leaf.fill",
            flavorText: "Grown from the dream of a forgotten garden."
        ),
        DreamkeeperDefinition(
            id: "crystal_golem",
            name: "Crystal Golem",
            element: .tide,
            role: .tank,
            rarity: .epic,
            baseStats: Stats(hp: 160, attack: 9, defense: 16, speed: 30),
            growthPerLevel: Stats(hp: 12, attack: 0.6, defense: 1.2, speed: 0.2),
            ultimate: UltimateSkill(name: "Bulwark Slam", description: "A ground-shaking blow that staggers the foe.", damageMultiplier: 1.9, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Guard Slam", description: "A heavy but unhurried blow.", effectMultiplier: 1.2, cooldownSeconds: 8),
            passive: PassiveTrait(name: "Crystalline Hide", description: "Refracts a portion of incoming force.", statBonus: Stats(hp: 10, attack: 0, defense: 2, speed: 0)),
            symbol: "diamond.fill",
            flavorText: "Formed where a tidal dream froze mid-wave."
        ),
        DreamkeeperDefinition(
            id: "star_wolf",
            name: "Star Wolf",
            element: .astral,
            role: .control,
            rarity: .epic,
            baseStats: Stats(hp: 105, attack: 14, defense: 9, speed: 58),
            growthPerLevel: Stats(hp: 8, attack: 1.2, defense: 0.6, speed: 0.6),
            ultimate: UltimateSkill(name: "Starfall Howl", description: "A resonant howl that freezes the enemy in place.", damageMultiplier: 1.7, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Quick Bite", description: "A fast snap before the foe can react.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Night Vision", description: "Never misses a step in the dark.", statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 3)),
            symbol: "pawprint.fill",
            flavorText: "Runs the paths between falling stars."
        ),
        DreamkeeperDefinition(
            id: "thorn_viper",
            name: "Thorn Viper",
            element: .bloom,
            role: .damage,
            rarity: .rare,
            baseStats: Stats(hp: 85, attack: 17, defense: 5, speed: 55),
            growthPerLevel: Stats(hp: 6.5, attack: 1.5, defense: 0.35, speed: 0.55),
            ultimate: UltimateSkill(name: "Venom Fang", description: "A precise strike laced with dream-thorn poison.", damageMultiplier: 2.3, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Puncture", description: "A jabbing strike aimed at the weak points.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Toxic Coating", description: "Fangs that never quite stop stinging.", statBonus: Stats(hp: 0, attack: 2, defense: 0, speed: 0)),
            symbol: "lizard.fill",
            flavorText: "Coils through brambles that grow only in restless dreams."
        ),
        DreamkeeperDefinition(
            id: "tide_serpent",
            name: "Tide Serpent",
            element: .tide,
            role: .damage,
            rarity: .uncommon,
            baseStats: Stats(hp: 80, attack: 14, defense: 5, speed: 50),
            growthPerLevel: Stats(hp: 6, attack: 1.2, defense: 0.35, speed: 0.45),
            ultimate: UltimateSkill(name: "Riptide Coil", description: "Wraps the foe in a crushing spiral of water.", damageMultiplier: 2.0, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Snap Coil", description: "A sudden lash of its coiled body.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Slippery Scales", description: "Hard to pin down, harder to catch.", statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 2)),
            symbol: "fish.fill",
            flavorText: "Slips between waves too quick for waking eyes to follow."
        ),
        DreamkeeperDefinition(
            id: "ember_phoenix",
            name: "Ember Phoenix",
            element: .ember,
            role: .healer,
            rarity: .legendary,
            baseStats: Stats(hp: 130, attack: 15, defense: 9, speed: 50),
            growthPerLevel: Stats(hp: 10, attack: 1.1, defense: 0.6, speed: 0.5),
            ultimate: UltimateSkill(name: "Rebirth Flame", description: "A blazing rebirth that mends every wound in the team.", damageMultiplier: 3.2, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Warm Feather", description: "Sheds a single ember-warm feather over an ally.", effectMultiplier: 1.2, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Eternal Ember", description: "A flame that refuses to be the last one out.", statBonus: Stats(hp: 12, attack: 2, defense: 0, speed: 0)),
            symbol: "bird.fill",
            flavorText: "Rises anew each time a dreamer refuses to give up."
        ),
        DreamkeeperDefinition(
            id: "lunar_owl",
            name: "Lunar Owl",
            element: .lunar,
            role: .control,
            rarity: .epic,
            baseStats: Stats(hp: 95, attack: 13, defense: 8, speed: 60),
            growthPerLevel: Stats(hp: 7, attack: 1.1, defense: 0.5, speed: 0.65),
            ultimate: UltimateSkill(name: "Silent Talons", description: "A soundless dive that leaves the target reeling.", damageMultiplier: 1.8, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Swift Peck", description: "A precise strike from above.", effectMultiplier: 1.3, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Keen Eyes", description: "Sees every opening before it appears.", statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 3)),
            symbol: "eye.fill",
            flavorText: "Watches from branches that exist only under a full moon."
        ),
        DreamkeeperDefinition(
            id: "astral_sentinel",
            name: "Astral Sentinel",
            element: .astral,
            role: .tank,
            rarity: .epic,
            baseStats: Stats(hp: 150, attack: 10, defense: 15, speed: 34),
            growthPerLevel: Stats(hp: 11, attack: 0.7, defense: 1.1, speed: 0.25),
            ultimate: UltimateSkill(name: "Starward Bulwark", description: "Calls down a wall of starlight to guard the team.", damageMultiplier: 1.7, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Brace", description: "Plants itself firm and strikes back.", effectMultiplier: 1.2, cooldownSeconds: 8),
            passive: PassiveTrait(name: "Astral Ward", description: "A quiet shimmer that deflects the worst of it.", statBonus: Stats(hp: 0, attack: 0, defense: 3, speed: 0)),
            symbol: "shield.lefthalf.filled",
            flavorText: "Stands guard at the border between dream and stars."
        ),
        DreamkeeperDefinition(
            id: "coral_warden",
            name: "Coral Warden",
            element: .tide,
            role: .support,
            rarity: .uncommon,
            baseStats: Stats(hp: 92, attack: 11, defense: 8, speed: 42),
            growthPerLevel: Stats(hp: 7, attack: 0.9, defense: 0.5, speed: 0.35),
            ultimate: UltimateSkill(name: "Tidal Chorus", description: "A rolling wave of encouragement washes over the team.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Encourage", description: "A steadying word that stiffens resolve.", effectMultiplier: 1.3, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Reef Guard", description: "Grew tough where the currents are roughest.", statBonus: Stats(hp: 0, attack: 0, defense: 2, speed: 0)),
            symbol: "water.waves",
            flavorText: "Grew from a reef that only blooms in deep sleep."
        ),
        DreamkeeperDefinition(
            id: "cinder_sprite",
            name: "Cinder Sprite",
            element: .ember,
            role: .support,
            rarity: .uncommon,
            baseStats: Stats(hp: 82, attack: 12, defense: 6, speed: 46),
            growthPerLevel: Stats(hp: 6.5, attack: 1.0, defense: 0.4, speed: 0.4),
            ultimate: UltimateSkill(name: "Spark Rally", description: "A shower of warm sparks lifts the whole team's spirit.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Warm Spark Jab", description: "A friendly spark that lifts the spirit.", effectMultiplier: 1.3, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Warm Spark", description: "A spark that never quite burns out, no matter the dark.", statBonus: Stats(hp: 0, attack: 2, defense: 0, speed: 0)),
            symbol: "flame.circle.fill",
            flavorText: "A spark that never quite burns out, no matter the dark."
        ),
        DreamkeeperDefinition(
            id: "flicker_pup",
            name: "Flicker Pup",
            element: .ember,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 65, attack: 11, defense: 4, speed: 46),
            growthPerLevel: Stats(hp: 5, attack: 0.9, defense: 0.3, speed: 0.4),
            ultimate: UltimateSkill(name: "Candle Charge", description: "A clumsy but eager charge wreathed in flickering flame.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Warm Nip", description: "A playful nip that's hotter than it looks.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Restless Spark", description: "Too excitable to ever stay still for long.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 1)),
            symbol: "pawprint.fill",
            flavorText: "Hatched from the last spark of a dream that almost went out."
        ),
        DreamkeeperDefinition(
            id: "ripple_minnow",
            name: "Ripple Minnow",
            element: .tide,
            role: .support,
            rarity: .common,
            baseStats: Stats(hp: 70, attack: 8, defense: 6, speed: 36),
            growthPerLevel: Stats(hp: 5, attack: 0.6, defense: 0.4, speed: 0.3),
            ultimate: UltimateSkill(name: "Shoal Surge", description: "A rush of small fish that steadies the whole team.", damageMultiplier: 1.3, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Nudge", description: "A gentle push in the right direction.", effectMultiplier: 1.2, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Safety in Numbers", description: "Never truly alone, even when it looks that way.", statBonus: Stats(hp: 4, attack: 0, defense: 0, speed: 0)),
            symbol: "fish.fill",
            flavorText: "Swims in the shallow end of dreams too small for anything bigger."
        ),
        DreamkeeperDefinition(
            id: "sprout_cub",
            name: "Sprout Cub",
            element: .bloom,
            role: .tank,
            rarity: .common,
            baseStats: Stats(hp: 95, attack: 6, defense: 9, speed: 24),
            growthPerLevel: Stats(hp: 7, attack: 0.4, defense: 0.6, speed: 0.2),
            ultimate: UltimateSkill(name: "Stubborn Root", description: "Plants itself down and simply refuses to move.", damageMultiplier: 1.3, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Headbutt", description: "An earnest, clumsy charge.", effectMultiplier: 1.1, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Thick Bark", description: "Young, but already tougher than it looks.", statBonus: Stats(hp: 5, attack: 0, defense: 1, speed: 0)),
            symbol: "tortoise.fill",
            flavorText: "A seedling dream that decided to grow claws instead of leaves."
        ),
        DreamkeeperDefinition(
            id: "nightling",
            name: "Nightling",
            element: .lunar,
            role: .control,
            rarity: .common,
            baseStats: Stats(hp: 68, attack: 9, defense: 5, speed: 48),
            growthPerLevel: Stats(hp: 5, attack: 0.7, defense: 0.35, speed: 0.4),
            ultimate: UltimateSkill(name: "Small Shadow", description: "Slips a sliver of dark across the enemy's eyes.", damageMultiplier: 1.4, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Flicker Step", description: "A quick sidestep into darkness and back.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Half-Seen", description: "Never quite where you expect it to be.", statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 2)),
            symbol: "moon.fill",
            flavorText: "A scrap of night that broke off before the dream was finished."
        ),
        DreamkeeperDefinition(
            id: "stardust_moth",
            name: "Stardust Moth",
            element: .astral,
            role: .healer,
            rarity: .common,
            baseStats: Stats(hp: 72, attack: 7, defense: 5, speed: 40),
            growthPerLevel: Stats(hp: 5, attack: 0.5, defense: 0.35, speed: 0.35),
            ultimate: UltimateSkill(name: "Dust Trail", description: "Sheds a fine, healing dust over the team.", damageMultiplier: 1.4, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Wing Flutter", description: "A soft flutter that eases an ally's pain.", effectMultiplier: 1.15, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Drawn to Light", description: "Follows whatever light is left in the fight.", statBonus: Stats(hp: 3, attack: 0, defense: 0, speed: 0)),
            symbol: "sparkle",
            flavorText: "Drawn to any dream still bright enough to see."
        ),
        DreamkeeperDefinition(
            id: "cinder_badger",
            name: "Cinder Badger",
            element: .ember,
            role: .tank,
            rarity: .uncommon,
            baseStats: Stats(hp: 112, attack: 8, defense: 11, speed: 28),
            growthPerLevel: Stats(hp: 8, attack: 0.6, defense: 0.75, speed: 0.3),
            ultimate: UltimateSkill(name: "Coal Dig", description: "Burrows in and erupts with banked heat.", damageMultiplier: 1.7, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Stubborn Charge", description: "Lowers its head and simply pushes through.", effectMultiplier: 1.25, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Banked Heat", description: "Runs warmer the longer a fight drags on.", statBonus: Stats(hp: 6, attack: 0, defense: 1, speed: 0)),
            symbol: "pawprint.fill",
            flavorText: "Digs its den where a hearth-fire dream burned down to embers."
        ),
        DreamkeeperDefinition(
            id: "pearl_otter",
            name: "Pearl Otter",
            element: .tide,
            role: .healer,
            rarity: .uncommon,
            baseStats: Stats(hp: 88, attack: 9, defense: 6, speed: 44),
            growthPerLevel: Stats(hp: 6.5, attack: 0.7, defense: 0.45, speed: 0.38),
            ultimate: UltimateSkill(name: "Pearl Tide", description: "A wave of luminous pearls mends the team's wounds.", damageMultiplier: 2.0, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Polish", description: "A quick, fussy grooming pass over an ally.", effectMultiplier: 1.2, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Buoyant", description: "Always finds a way to stay afloat.", statBonus: Stats(hp: 5, attack: 0, defense: 0, speed: 0)),
            symbol: "drop.fill",
            flavorText: "Collects pearls from dreams too calm to ever make waves."
        ),
        DreamkeeperDefinition(
            id: "comet_fox",
            name: "Comet Fox",
            element: .astral,
            role: .damage,
            rarity: .uncommon,
            baseStats: Stats(hp: 78, attack: 13, defense: 5, speed: 50),
            growthPerLevel: Stats(hp: 6, attack: 1.0, defense: 0.35, speed: 0.42),
            ultimate: UltimateSkill(name: "Streaking Dash", description: "A blinding dash that leaves a trail of light.", damageMultiplier: 1.9, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Tail Flash", description: "A quick flick of a glowing tail.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Trailing Light", description: "Leaves the air shimmering just from passing through.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 1)),
            symbol: "hare.fill",
            flavorText: "Chases the tail of an actual comet through the dream sky and usually wins."
        ),
        DreamkeeperDefinition(
            id: "bramble_lynx",
            name: "Bramble Lynx",
            element: .bloom,
            role: .control,
            rarity: .rare,
            baseStats: Stats(hp: 90, attack: 13, defense: 7, speed: 56),
            growthPerLevel: Stats(hp: 7, attack: 1.1, defense: 0.45, speed: 0.5),
            ultimate: UltimateSkill(name: "Thicket Pounce", description: "Vanishes into brush and strikes from an angle no one expects.", damageMultiplier: 2.0, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Claw Rake", description: "A fast, low rake across the legs.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Thorned Coat", description: "Grew its fur through a hedge of brambles.", statBonus: Stats(hp: 0, attack: 1, defense: 1, speed: 0)),
            symbol: "leaf.fill",
            flavorText: "Stalks the hedgerows of a garden dream no one remembers planting."
        ),
        DreamkeeperDefinition(
            id: "shade_panther",
            name: "Shade Panther",
            element: .lunar,
            role: .damage,
            rarity: .rare,
            baseStats: Stats(hp: 92, attack: 18, defense: 6, speed: 58),
            growthPerLevel: Stats(hp: 7, attack: 1.5, defense: 0.4, speed: 0.55),
            ultimate: UltimateSkill(name: "Moonless Strike", description: "A strike timed to the one moment no light reaches it.", damageMultiplier: 2.3, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Silent Pounce", description: "Crosses the distance before the sound catches up.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Unseen", description: "Blends into whatever shadow it's standing in.", statBonus: Stats(hp: 0, attack: 2, defense: 0, speed: 0)),
            symbol: "moon.stars.fill",
            flavorText: "Hunts on the nights the moon forgets to rise at all."
        ),
        DreamkeeperDefinition(
            id: "nova_falcon",
            name: "Nova Falcon",
            element: .astral,
            role: .control,
            rarity: .rare,
            baseStats: Stats(hp: 88, attack: 13, defense: 7, speed: 62),
            growthPerLevel: Stats(hp: 6.5, attack: 1.1, defense: 0.45, speed: 0.55),
            ultimate: UltimateSkill(name: "Nova Dive", description: "A screaming dive trailing a burst of starlight.", damageMultiplier: 1.9, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Wing Cut", description: "A sharp turn that clips the target mid-flight.", effectMultiplier: 1.3, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Updraft", description: "Rides currents that only it can feel.", statBonus: Stats(hp: 0, attack: 0, defense: 0, speed: 3)),
            symbol: "bird.fill",
            flavorText: "Nests at the peak of a mountain that only exists at the top of a dream."
        ),
        DreamkeeperDefinition(
            id: "magma_titan",
            name: "Magma Titan",
            element: .ember,
            role: .tank,
            rarity: .epic,
            baseStats: Stats(hp: 170, attack: 11, defense: 17, speed: 28),
            growthPerLevel: Stats(hp: 13, attack: 0.8, defense: 1.3, speed: 0.22),
            ultimate: UltimateSkill(name: "Molten Fist", description: "A slow, unstoppable punch of liquid rock.", damageMultiplier: 2.1, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Heat Wall", description: "Radiates enough heat to make the whole front line flinch.", effectMultiplier: 1.25, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Molten Core", description: "Never quite cools down enough to be safe to touch.", statBonus: Stats(hp: 12, attack: 0, defense: 2, speed: 0)),
            symbol: "flame.fill",
            flavorText: "Stands where a mountain-sized dream slowly finished melting."
        ),
        DreamkeeperDefinition(
            id: "verdant_stag",
            name: "Verdant Stag",
            element: .bloom,
            role: .support,
            rarity: .epic,
            baseStats: Stats(hp: 125, attack: 14, defense: 11, speed: 48),
            growthPerLevel: Stats(hp: 9, attack: 1.1, defense: 0.8, speed: 0.4),
            ultimate: UltimateSkill(name: "Antler Bloom", description: "Flowers burst from its antlers, lifting the whole team.", damageMultiplier: 1.7, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Proud Charge", description: "A dignified, unhurried charge.", effectMultiplier: 1.3, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Old Growth", description: "Carries the calm of a forest that's stood for ages.", statBonus: Stats(hp: 8, attack: 0, defense: 1, speed: 0)),
            symbol: "leaf.fill",
            flavorText: "Wears a crown grown from a forest's oldest, gentlest dream."
        ),
        DreamkeeperDefinition(
            id: "abyssal_kraken",
            name: "Abyssal Kraken",
            element: .tide,
            role: .damage,
            rarity: .epic,
            baseStats: Stats(hp: 118, attack: 19, defense: 8, speed: 46),
            growthPerLevel: Stats(hp: 9, attack: 1.6, defense: 0.5, speed: 0.4),
            ultimate: UltimateSkill(name: "Deep Grasp", description: "Coils dragged up from the trench close around the target.", damageMultiplier: 2.2, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Tentacle Lash", description: "A heavy lash from somewhere just out of sight.", effectMultiplier: 1.35, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Trench Pressure", description: "Hits harder the deeper the fight goes.", statBonus: Stats(hp: 0, attack: 2, defense: 0, speed: 0)),
            symbol: "tropicalstorm",
            flavorText: "Rose once from a dream so deep even the tide forgot it was there."
        ),
        DreamkeeperDefinition(
            id: "leviathan_queen",
            name: "Leviathan Queen",
            element: .tide,
            role: .tank,
            rarity: .legendary,
            baseStats: Stats(hp: 200, attack: 13, defense: 20, speed: 36),
            growthPerLevel: Stats(hp: 15, attack: 1.0, defense: 1.5, speed: 0.3),
            ultimate: UltimateSkill(name: "Tidal Crown", description: "Calls up a crown of water that crashes down on every foe.", damageMultiplier: 2.6, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Regal Wave", description: "A slow, commanding push of current.", effectMultiplier: 1.3, cooldownSeconds: 8),
            passive: PassiveTrait(name: "Sovereign Tide", description: "The ocean itself seems to defer to her.", statBonus: Stats(hp: 14, attack: 0, defense: 2, speed: 0)),
            symbol: "water.waves",
            flavorText: "Rules every current in the dream ocean, and every current knows it."
        ),
        DreamkeeperDefinition(
            id: "world_tree_warden",
            name: "World Tree Warden",
            element: .bloom,
            role: .healer,
            rarity: .legendary,
            baseStats: Stats(hp: 150, attack: 13, defense: 12, speed: 44),
            growthPerLevel: Stats(hp: 11, attack: 1.0, defense: 0.9, speed: 0.35),
            ultimate: UltimateSkill(name: "Root of Ages", description: "Draws on a root older than the forest to mend the whole team.", damageMultiplier: 3.0, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Sap Blessing", description: "A slow, warm trickle of restorative sap.", effectMultiplier: 1.25, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Ancient Roots", description: "Reaches deeper than any dream has ever needed.", statBonus: Stats(hp: 14, attack: 0, defense: 1, speed: 0)),
            symbol: "leaf.fill",
            flavorText: "Grew from the very first seed a dreamer ever planted."
        ),
        DreamkeeperDefinition(
            id: "celestial_dragon",
            name: "Celestial Dragon",
            element: .astral,
            role: .damage,
            rarity: .mythic,
            baseStats: Stats(hp: 155, attack: 24, defense: 11, speed: 58),
            growthPerLevel: Stats(hp: 12, attack: 1.9, defense: 0.7, speed: 0.5),
            ultimate: UltimateSkill(name: "Starfire Cataclysm", description: "Breathes out the light of a dying galaxy.", damageMultiplier: 3.6, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Comet Bite", description: "A bite that still carries the heat of falling through the sky.", effectMultiplier: 1.4, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Living Constellation", description: "Made of the same stuff as the stars it flies among.", statBonus: Stats(hp: 10, attack: 3, defense: 0, speed: 0)),
            symbol: "atom",
            flavorText: "The last dream every dreamer has, if they dream long enough."
        ),
        DreamkeeperDefinition(
            id: "eclipse_empress",
            name: "Eclipse Empress",
            element: .lunar,
            role: .control,
            rarity: .mythic,
            baseStats: Stats(hp: 140, attack: 17, defense: 13, speed: 64),
            growthPerLevel: Stats(hp: 11, attack: 1.3, defense: 1.0, speed: 0.55),
            ultimate: UltimateSkill(name: "Total Eclipse", description: "Blots out every light at once, leaving the enemy nowhere to hide.", damageMultiplier: 3.3, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Crescent Edict", description: "A single, absolute command carved in moonlight.", effectMultiplier: 1.4, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Sovereign of Shadow", description: "Every dark corner of the dream answers to her.", statBonus: Stats(hp: 0, attack: 2, defense: 1, speed: 2)),
            symbol: "crown.fill",
            flavorText: "Rules the space between one dream ending and the next beginning."
        ),

        // MARK: - Exclusive (Igo & Ames)
        //
        // Not Dreamkeepers at all, strictly speaking — Igo and Ames are the
        // only two humans who ever stayed in Dream Haven for good.
        // Dreamkeepers call them "Dreamwalker," never one of their own kind,
        // and they never claimed to be. See `Rarity.exclusive` and `TwinBond`.
        DreamkeeperDefinition(
            id: "igo",
            name: "Igo",
            element: .tide,
            role: .guardian,
            rarity: .exclusive,
            baseStats: Stats(hp: 200, attack: 20, defense: 24, speed: 56),
            growthPerLevel: Stats(hp: 16, attack: 1.3, defense: 1.7, speed: 0.4),
            ultimate: UltimateSkill(name: "Flutwand", description: "Raises a protective wall of water around the whole team.", damageMultiplier: 1.0, attacksToCharge: 5),
            activeSkill: ActiveSkill(name: "Strömungsriss", description: "A tearing current that damages and slows the enemy.", effectMultiplier: 1.3, cooldownSeconds: 7),
            passive: PassiveTrait(name: "Gezeitenwache", description: "Once per battle, refuses to fall and surges back at 30% HP.", statBonus: .zero, reviveHPFraction: 0.3),
            symbol: "shield.lefthalf.filled",
            flavorText: "Not a creature of the dream at all — Igo is one of only two humans who ever stayed in Dream Haven for good, an outsider who chose to become its shield. The Dreamkeepers call him Dreamwalker, never one of their own, and he wouldn't have it any other way."
        ),
        DreamkeeperDefinition(
            id: "ames",
            name: "Ames",
            element: .ember,
            role: .damage,
            rarity: .exclusive,
            baseStats: Stats(hp: 165, attack: 30, defense: 15, speed: 66),
            growthPerLevel: Stats(hp: 12, attack: 2.2, defense: 0.9, speed: 0.6),
            ultimate: UltimateSkill(name: "Glutschnitt", description: "A single devastating cut of white-hot flame.", damageMultiplier: 3.8, attacksToCharge: 4),
            activeSkill: ActiveSkill(name: "Aschesturm", description: "A burning strike that keeps the enemy smoldering.", effectMultiplier: 1.5, cooldownSeconds: 6),
            passive: PassiveTrait(name: "Feuertaufe", description: "Hits harder the closer she comes to falling — up to +60% attack near death.", statBonus: .zero, lowHPAttackBonus: 0.6),
            symbol: "flame.fill",
            flavorText: "Ames walked into Dream Haven once and simply never left — the second of the two humans who made this place home for good. No creature of dream burns quite like she does; the fire is entirely, stubbornly hers."
        ),

        // MARK: - Olf

        // The joke starter every new save begins with. All six entries here
        // share `family: "olf"` (see `DreamkeeperDefinition.family`) so any
        // of them pulled later from Summoning can be fused straight into
        // whichever one the player is actually raising, and all six are
        // literally named "Olf" so `DreamkeeperArt` resolves every one of
        // them to the same single portrait — there's only one Olf, he just
        // picked a favorite element (or, if you know the trick, isn't quite
        // what he first appeared to be).
        DreamkeeperDefinition(
            id: "olf_ember",
            name: "Olf",
            element: .ember,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 62, attack: 10, defense: 4, speed: 42),
            growthPerLevel: Stats(hp: 4.6, attack: 0.75, defense: 0.28, speed: 0.35),
            ultimate: UltimateSkill(name: "Wobbly Flame Lunge", description: "Charges in swinging his twig sword, somehow catching fire on the way.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Hot-Headed Jab", description: "A jab thrown with more enthusiasm than technique.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Too Dumb to Be Scared", description: "Doesn't know enough to flinch.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 0)),
            symbol: "theatermasks.fill",
            flavorText: "Every save starts with an Olf. Nobody's quite sure why he insists on the tunic.",
            family: "olf"
        ),
        DreamkeeperDefinition(
            id: "olf_tide",
            name: "Olf",
            element: .tide,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 62, attack: 10, defense: 4, speed: 42),
            growthPerLevel: Stats(hp: 4.6, attack: 0.75, defense: 0.28, speed: 0.35),
            ultimate: UltimateSkill(name: "Bellyflop Splash", description: "Cannonballs in, mostly to see what happens.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Puddle Poke", description: "Pokes the nearest foe with his twig sword, dripping.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Too Dumb to Be Scared", description: "Doesn't know enough to flinch.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 0)),
            symbol: "theatermasks.fill",
            flavorText: "Chose Tide because puddles seemed friendlier than the alternative.",
            family: "olf"
        ),
        DreamkeeperDefinition(
            id: "olf_bloom",
            name: "Olf",
            element: .bloom,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 62, attack: 10, defense: 4, speed: 42),
            growthPerLevel: Stats(hp: 4.6, attack: 0.75, defense: 0.28, speed: 0.35),
            ultimate: UltimateSkill(name: "Overgrown Tantrum", description: "Flails wildly through the underbrush he mostly grew himself.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Twig Sword Thwack", description: "A thwack from the twig sword — which is, appropriately, also a twig.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Too Dumb to Be Scared", description: "Doesn't know enough to flinch.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 0)),
            symbol: "theatermasks.fill",
            flavorText: "His sword and his element are, technically, the same plant.",
            family: "olf"
        ),
        DreamkeeperDefinition(
            id: "olf_lunar",
            name: "Olf",
            element: .lunar,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 62, attack: 10, defense: 4, speed: 42),
            growthPerLevel: Stats(hp: 4.6, attack: 0.75, defense: 0.28, speed: 0.35),
            ultimate: UltimateSkill(name: "Moonstruck Stumble", description: "Trips over his own feet directly into the enemy, somehow on purpose.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Sleepy Swipe", description: "A swipe thrown half-asleep, which is most of the time.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Too Dumb to Be Scared", description: "Doesn't know enough to flinch.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 0)),
            symbol: "theatermasks.fill",
            flavorText: "Picked Lunar because he liked staying up. He is always tired.",
            family: "olf"
        ),
        DreamkeeperDefinition(
            id: "olf_astral",
            name: "Olf",
            element: .astral,
            role: .damage,
            rarity: .common,
            baseStats: Stats(hp: 62, attack: 10, defense: 4, speed: 42),
            growthPerLevel: Stats(hp: 4.6, attack: 0.75, defense: 0.28, speed: 0.35),
            ultimate: UltimateSkill(name: "Starry-Eyed Charge", description: "Charges in staring at the sky instead of the enemy.", damageMultiplier: 1.5, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Lucky Jab", description: "A jab he definitely meant to land.", effectMultiplier: 1.2, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Too Dumb to Be Scared", description: "Doesn't know enough to flinch.", statBonus: Stats(hp: 0, attack: 1, defense: 0, speed: 0)),
            symbol: "theatermasks.fill",
            flavorText: "Believes the stars picked him. The stars have not commented.",
            family: "olf"
        ),
        // Never rolled by Summoning (`isSummonable: false`) — granted only
        // by holding the Ember option for 5 seconds on the post-onboarding
        // starter-element screen. Exactly +10% over the plain Olf's stats
        // in every field, per the secret's own promise.
        DreamkeeperDefinition(
            id: "olf_ultimate",
            name: "Olf",
            element: .ember,
            role: .damage,
            rarity: .rare,
            baseStats: Stats(hp: 68.2, attack: 11, defense: 4.4, speed: 46.2),
            growthPerLevel: Stats(hp: 5.06, attack: 0.825, defense: 0.308, speed: 0.385),
            ultimate: UltimateSkill(name: "Unlikely Hero's Flame Lunge", description: "The same wobbly lunge — somehow, this time, it actually connects.", damageMultiplier: 1.65, attacksToCharge: 3),
            activeSkill: ActiveSkill(name: "Suspiciously Competent Jab", description: "A jab that lands exactly where he meant it to. He looks as surprised as you.", effectMultiplier: 1.32, cooldownSeconds: 5),
            passive: PassiveTrait(name: "Secretly Built Different", description: "Somehow, against all odds, this Olf turned out unfairly strong.", statBonus: Stats(hp: 4, attack: 1, defense: 1, speed: 1)),
            symbol: "theatermasks.fill",
            flavorText: "The other Olf isn't sure how this happened either.",
            family: "olf",
            isSummonable: false
        )
    ])

    /// Order new Dreamkeepers unlock in as the campaign progresses; the rest
    /// of the catalog is summon-only, reached via the Dream Shrine.
    static let unlockOrder = ["ember_fox", "moon_hare", "crystal_golem", "forest_spirit", "star_wolf"]

    /// Every new save's starter, before the post-onboarding screen locks in
    /// an element (or, via the secret gesture, Ultimate Olf) — see
    /// `GameState.needsStarterOlfChoice`/`chooseStarterOlf(element:)`. Fire
    /// is the default because it's also the element the secret gesture
    /// hides behind, so a player who never touches the choice screen still
    /// ends up with a normal, fully playable Fire Olf.
    static let starterOlfDefaultID = "olf_ember"

    /// Granted only by the secret 5-second hold on Ember during the
    /// starter-element screen; never reachable via Summoning.
    static let ultimateOlfID = "olf_ultimate"

    static func olfDefinitionID(for element: Element) -> String { "olf_\(element.rawValue)" }
}
