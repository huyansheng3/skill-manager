import Foundation

struct Workspace: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rootPath: URL
    let skillsPath: URL

    var displayName: String {
        name.isEmpty ? rootPath.lastPathComponent : name
    }
}
