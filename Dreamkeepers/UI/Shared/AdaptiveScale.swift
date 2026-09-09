import SwiftUI

/// Uniformly shrinks a fixed (non-scrolling) landscape layout to fit
/// whatever screen it actually ends up on, instead of letting content
/// clip or overflow on a smaller phone.
///
/// A few hub-style screens (`DreamHavenView`, `ProfileView`) are
/// deliberately laid out without a `ScrollView` — they're meant to read at
/// a glance, not be scrolled — which was tuned against a reference
/// landscape size around the iPhone 17 Pro (~874×402pt). iPhone SE-class
/// phones are meaningfully smaller in landscape (~667×375pt on the current
/// smallest supported size), so without this, their fixed-height cards can
/// run out of vertical room and get clipped at the bottom edge.
///
/// This measures the real available space with `GeometryReader`, lays the
/// content out at its natural reference size, and scales the whole thing
/// uniformly to fill it — down on smaller phones so nothing clips, and
/// (when `maxScale` allows it) up on bigger phones so the layout doesn't
/// sit shrunk-and-stranded in a sea of empty space either.
struct AdaptiveScale: ViewModifier {
    /// The landscape point size this screen's fixed layout was designed
    /// and tuned against (iPhone 17 Pro-class).
    var referenceSize: CGSize = CGSize(width: 874, height: 402)
    /// Upper bound on the scale factor. `1` (default) never scales up —
    /// bigger phones just get the reference layout's normal spacing.
    /// Pass something like `1.3` to let it grow on larger screens too;
    /// keep it modest since `scaleEffect` upscaling blurs text a bit
    /// (it stretches the rasterized content instead of re-rendering it).
    var maxScale: CGFloat = 1

    func body(content: Content) -> some View {
        GeometryReader { geo in
            let scale = min(maxScale, min(geo.size.width / referenceSize.width, geo.size.height / referenceSize.height))
            content
                .frame(width: referenceSize.width, height: referenceSize.height)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

extension View {
    /// Applies `AdaptiveScale` — use on fixed, non-`ScrollView` landscape
    /// hub screens so smaller phones see the whole layout shrunk instead of
    /// clipped. Leave screens that already use `ScrollView` alone; they
    /// already handle smaller screens by scrolling.
    func adaptiveScale(reference: CGSize = CGSize(width: 874, height: 402), maxScale: CGFloat = 1) -> some View {
        modifier(AdaptiveScale(referenceSize: reference, maxScale: maxScale))
    }
}
