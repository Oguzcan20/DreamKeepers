import Foundation

/// A named lineup of deployed Dreamkeepers. MVP ships a single "Main Team";
/// multiple named teams (spec: Team System) slot in later without changing
/// this model.
struct Team: Codable, Identifiable, Equatable {
    static let maxSize = 4

    var id: UUID
    var name: String
    var memberIDs: [UUID]

    init(id: UUID = UUID(), name: String = "Main Team", memberIDs: [UUID] = []) {
        self.id = id
        self.name = name
        self.memberIDs = memberIDs
    }
}
