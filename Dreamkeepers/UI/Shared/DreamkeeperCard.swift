import SwiftUI

struct DreamkeeperCard: View {
    let definition: DreamkeeperDefinition
    let instance: DreamkeeperInstance
    var isDeployed: Bool = false
    /// Non-nil while the roster grid is in sell-selection mode — true means
    /// this card is one of the ones currently picked to sell. Nil (the
    /// default) hides the selection checkmark entirely for every other use
    /// of this card.
    var isSelectedForSale: Bool? = nil
    /// Igo/Ames only — nil hides the badge entirely for the other 30
    /// characters. See `TwinBond`.
    var twinBondActive: Bool? = nil
    var onTap: (() -> Void)?

    private var hasArt: Bool { DreamkeeperArt.hasArt(for: definition.name) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if hasArt {
                    Image(DreamkeeperArt.assetName(for: definition.name))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .shadow(color: definition.rarity.glows ? definition.element.color.opacity(0.7) : .clear, radius: 10)
                } else {
                    Circle()
                        .fill(definition.rarity.gradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: definition.rarity.glows ? definition.element.color.opacity(0.7) : .clear, radius: 10)
                    Image(systemName: definition.symbol)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: definition.element.symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(definition.element.color)
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            // Most names ("Astral Sentinel", "Celestial Dragon") don't fit
            // this card's 96pt width on one line — a bare `.lineLimit(1)`
            // silently ellipsized almost every entry in the roster grid.
            // Two lines + a shrink fallback keeps the full name legible
            // instead of "Astral Sent…" everywhere.
            Text(definition.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            Text("Lv \(instance.level)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))

            StarRow(stars: instance.stars)

            if let twinBondActive {
                Text("Twin Bond")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(twinBondActive ? Theme.gold : .white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(twinBondActive ? Theme.gold.opacity(0.18) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule().stroke(twinBondActive ? Theme.gold : .white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(10)
        .frame(width: 96)
        .background(isDeployed ? Theme.violet.opacity(0.25) : Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isDeployed ? Theme.gold : Theme.cardStroke, lineWidth: isDeployed ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topLeading) {
            if let isSelectedForSale {
                Image(systemName: isSelectedForSale ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelectedForSale ? Theme.gold : .white.opacity(0.5))
                    .background(Circle().fill(Theme.deepNavy.opacity(0.6)).padding(-1))
                    .offset(x: 4, y: 4)
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits((isDeployed || isSelectedForSale == true) ? .isSelected : [])
    }
}
