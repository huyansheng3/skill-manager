import Foundation

struct Workspace: Identifiable, Equatable {
    let id: UUID
    let name: String
    let rootPath: String
    let skillsPath: URL

    var displayName: String {
        name.isEmpty ? (rootPath as NSString).lastPathComponent : name
    }
}
