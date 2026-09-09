import SwiftUI
import GameKit

/// Bridges Apple's UIKit-only `GKGameCenterViewController` (leaderboards,
/// achievements, friends) into SwiftUI — there's no native SwiftUI
/// equivalent for the built-in Game Center overlay.
struct GameCenterOverlay: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var leaderboardID: String?

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented, uiViewController.presentedViewController == nil {
            let gcVC: GKGameCenterViewController
            if let leaderboardID {
                gcVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
            } else {
                gcVC = GKGameCenterViewController(state: .default)
            }
            gcVC.gameCenterDelegate = context.coordinator
            uiViewController.present(gcVC, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let parent: GameCenterOverlay
        init(_ parent: GameCenterOverlay) { self.parent = parent }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
            parent.isPresented = false
        }
    }
}

extension UIApplication {
    /// Used to give `GameCenterService` somewhere to present the system
    /// Game Center login sheet from, since that's a UIKit-only flow.
    static var dk_rootViewController: UIViewController? {
        shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
