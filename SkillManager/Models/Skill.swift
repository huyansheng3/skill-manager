import Foundation

struct Skill: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let author: String?
    let path: URL
    let location: SkillLocation
    var isEnabled: Bool
    let size: Int64

    init(
        id: UUID,
        name: String,
        description: String? = nil,
        author: String? = nil,
        path: URL,
        location: SkillLocation,
        isEnabled: Bool,
        size: Int64
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.author = author
        self.path = path
        self.location = location
        self.isEnabled = isEnabled
        self.size = size
    }

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
