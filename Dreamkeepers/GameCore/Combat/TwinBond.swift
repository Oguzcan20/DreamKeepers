import Foundation

/// Igo and Ames were the only two humans who ever stayed in Dream Haven —
/// their bond only manifests when they fight side by side.
enum TwinBond {
    static let igoID = "igo"
    static let amesID = "ames"
    /// +75% ATK/DEF for both, only while both are in the active battle formation.
    static let statBonusMultiplier = 0.75

    static func isActive(memberDefinitionIDs ids: some Sequence<String>) -> Bool {
        let set = Set(ids)
        return set.contains(igoID) && set.contains(amesID)
    }

    static func isBondCharacter(_ definitionID: String) -> Bool {
        definitionID == igoID || definitionID == amesID
    }

    static func partnerID(of definitionID: String) -> String? {
        if definitionID == igoID { return amesID }
        if definitionID == amesID { return igoID }
        return nil
    }
}
