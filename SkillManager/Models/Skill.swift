import Foundation

struct Skill: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String? = nil
    let author: String? = nil
    let path: URL
    let location: SkillLocation
    var isEnabled: Bool
    let size: Int64

    var workspaceId: UUID? {
        if case .workspace(let id) = location {
            return id
        }
        return nil
    }

    var displayName: String {
        if isEnabled {
            return name
        } else {
            return name.replacingOccurrences(of: ".disabled", with: "")
        }
    }

    var isDisabled: Bool { !isEnabled }
}
