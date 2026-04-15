import Foundation

struct Skill: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let author: String?
    let path: URL
    let location: SkillLocation
    var isEnabled: Bool
    let workspaceId: UUID?
    let size: Int64

    var displayName: String {
        if isEnabled {
            return name
        } else {
            return name.replacingOccurrences(of: ".disabled", with: "")
        }
    }

    var isDisabled: Bool { !isEnabled }
}
