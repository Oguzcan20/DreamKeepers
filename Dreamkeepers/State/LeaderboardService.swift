import Foundation
import Observation
import GameKit

/// Submits campaign progress to Game Center's leaderboard. The leaderboard
/// ID below is a placeholder — Game Center silently ignores submissions to
/// an ID that hasn't been created in App Store Connect (no crash, no error
/// surfaced to the player), which requires a paid Apple Developer account.
/// Once the leaderboard is created there with this same ID, submissions
/// start counting immediately with no code changes.
@MainActor
@Observable
final class LeaderboardService {
    static let campaignProgressID = "com.dreamhaven.dreamkeepers.leaderboard.campaignstage"

    private(set) var lastSubmissionError: String?
    private var lastSubmittedStage: Int?

    func submitCampaignProgress(stage: Int) {
        guard GKLocalPlayer.local.isAuthenticated, stage != lastSubmittedStage else { return }
        lastSubmittedStage = stage
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    stage, context: 0, player: GKLocalPlayer.local,
                    leaderboardIDs: [Self.campaignProgressID]
                )
                lastSubmissionError = nil
            } catch {
                lastSubmissionError = error.localizedDescription
            }
        }
    }
}
