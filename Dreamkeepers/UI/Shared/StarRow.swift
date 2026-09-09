import SwiftUI

/// Compact star-rating row shared by Dreamkeeper cards and the fusion sheet —
/// filled stars up to `stars`, outlined slots for the remainder up to
/// `StarFusionSystem.maxStars`.
struct StarRow: View {
    var stars: Int
    var size: Font = .caption2

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<StarFusionSystem.maxStars, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(size)
                    .foregroundStyle(index < stars ? Theme.gold : .white.opacity(0.25))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(stars) of \(StarFusionSystem.maxStars) stars"))
    }
}
