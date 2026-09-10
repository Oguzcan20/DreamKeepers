import SwiftUI
import UIKit

extension UIScreen {
    /// The screen's bounds minus the current key window's safe-area insets —
    /// the region a full-screen view can actually fill without being clipped
    /// by the notch / Dynamic Island or the home indicator.
    ///
    /// This app is landscape-locked and several fixed screens historically
    /// force-fit themselves to `UIScreen.main.bounds.size` to sidestep a
    /// SwiftUI layout-proposal bug — but raw bounds is *larger* than the
    /// visible content area, so that force-fit clipped the header (and its
    /// back button) a few points off the top/bottom edges. Forcing to this
    /// value instead keeps the "don't trust the proposed size" behaviour
    /// while landing inside the actually-visible region. Falls back to raw
    /// bounds when no window is available yet.
    static var dk_safeContentSize: CGSize {
        let bounds = main.bounds
        let insets = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .safeAreaInsets ?? .zero
        return CGSize(
            width: max(0, bounds.width - insets.left - insets.right),
            height: max(0, bounds.height - insets.top - insets.bottom)
        )
    }
}

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
            // Defends against a recurring quirk on this landscape-locked app
            // where a view sharing a ZStack with an `.ignoresSafeArea()`
            // sibling is occasionally proposed the full screen height rather
            // than the safe-area height: clamp the size the scale is solved
            // against to the real visible content region, so the layout is
            // never measured against — or scaled to fill — a box taller than
            // the screen (which is exactly what pushed headers off the top
            // edge before).
            let safe = UIScreen.dk_safeContentSize
            let available = CGSize(
                width: min(geo.size.width, safe.width > 0 ? safe.width : geo.size.width),
                height: min(geo.size.height, safe.height > 0 ? safe.height : geo.size.height)
            )
            let scale = min(maxScale, min(available.width / referenceSize.width, available.height / referenceSize.height))
            content
                .frame(width: referenceSize.width, height: referenceSize.height)
                .scaleEffect(scale)
                .frame(width: available.width, height: available.height)
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
