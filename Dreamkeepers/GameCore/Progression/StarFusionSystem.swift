import Foundation

/// Shared duplicate-fusion math for both Dreamkeepers and Equipment: instead
/// of instantly converting a duplicate pull/drop into a star, every
/// duplicate becomes its own real inventory copy, and the player manually
/// picks which ones to feed into a fusion (see `GameState.fuseDreamkeeper`).
/// Star N costs 4*N duplicates, so reaching max star costs 4+8+12+16+20 = 60
/// duplicates total across the five tiers.
enum StarFusionSystem {
    static let maxStars = 5

    /// Duplicates required to fuse from `tier - 1` stars up to `tier` stars.
    /// `tier` is 1-indexed (the star level being fused *into*).
    static func duplicatesRequired(forTier tier: Int) -> Int {
        tier * 4
    }

    /// Whether `stars` at `duplicatesOwned` can fuse one tier higher.
    static func canFuse(stars: Int, duplicatesOwned: Int) -> Bool {
        guard stars < maxStars else { return false }
        return duplicatesOwned >= duplicatesRequired(forTier: stars + 1)
    }

    /// Banks `newDuplicates` onto `progress` and resolves as many tier-ups
    /// as the combined total supports (usually zero or one, but a big batch
    /// — or progress already sitting close to the threshold — can clear
    /// more than one at once). A fuse no longer has to hand over a tier's
    /// full cost in a single go: 3 now, 8 later, 5 later, 4 last all add up
    /// the same as 20 at once, whatever order the player happens to pull
    /// duplicates in.
    static func applyFusion(newDuplicates: Int, stars: Int, progress: Int) -> (stars: Int, progress: Int) {
        var stars = stars
        var progress = progress + newDuplicates
        while stars < maxStars, progress >= duplicatesRequired(forTier: stars + 1) {
            progress -= duplicatesRequired(forTier: stars + 1)
            stars += 1
        }
        return (stars, progress)
    }

    /// Per-star stat multiplier, matching the existing 6%-of-base-per-star
    /// bonus so equipment fusion feels consistent with Dreamkeeper fusion.
    static let statBonusPerStar = 0.06
}
