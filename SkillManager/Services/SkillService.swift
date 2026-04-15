import Foundation

actor SkillService {
    private let fileSystem: FileSystem

    init(fileSystem: FileSystem = .shared) {
        self.fileSystem = fileSystem
    }

    func moveSkill(_ skill: Skill, to workspace: Workspace) async throws {
        let destName = skill.isEnabled ? skill.displayName : "\(skill.displayName).disabled"
        let destinationURL = workspace.skillsPath.appendingPathComponent(destName)

        try await fileSystem.createDirectoryIfNeeded(at: workspace.skillsPath)
        try await fileSystem.moveItem(from: skill.path, to: destinationURL)
    }

    func moveSkillToGlobal(_ skill: Skill, globalPath: String = "~/.claude/skills") async throws {
        let expandedGlobalPath = (globalPath as NSString).expandingTildeInPath
        let globalURL = URL(fileURLWithPath: expandedGlobalPath)
        let destName = skill.isEnabled ? skill.displayName : "\(skill.displayName).disabled"
        let destinationURL = globalURL.appendingPathComponent(destName)

        try await fileSystem.createDirectoryIfNeeded(at: globalURL)
        try await fileSystem.moveItem(from: skill.path, to: destinationURL)
    }

    func toggleEnableDisable(_ skill: Skill) async throws {
        let parentDir = skill.path.deletingLastPathComponent()
        let currentName = skill.path.lastPathComponent

        if skill.isEnabled {
            // Disable: rename to .disabled
            let newName = "\(currentName).disabled"
            let newPath = parentDir.appendingPathComponent(newName)
            try await fileSystem.moveItem(from: skill.path, to: newPath)
        } else {
            // Enable: remove .disabled suffix
            let newName = currentName.replacingOccurrences(of: ".disabled", with: "")
            let newPath = parentDir.appendingPathComponent(newName)
            try await fileSystem.moveItem(from: skill.path, to: newPath)
        }
    }

    func deleteSkill(_ skill: Skill) async throws {
        try await fileSystem.removeItem(at: skill.path)
    }
}
