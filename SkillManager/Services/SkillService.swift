import Foundation

actor SkillService {
    private let fileSystem: FileSystem

    init(fileSystem: FileSystem = .shared) {
        self.fileSystem = fileSystem
    }

    func moveSkill(_ skill: Skill, to workspace: Workspace) throws {
        let destName = skill.isEnabled ? skill.displayName : "\(skill.displayName).disabled"
        let destinationURL = workspace.skillsPath.appendingPathComponent(destName)

        try fileSystem.createDirectoryIfNeeded(at: workspace.skillsPath)
        try fileSystem.moveItem(from: skill.path, to: destinationURL)
    }

    func moveSkillToGlobal(_ skill: Skill, globalPath: String = "~/.claude/skills") throws {
        let expandedGlobalPath = (globalPath as NSString).expandingTildeInPath
        let globalURL = URL(fileURLWithPath: expandedGlobalPath)
        let destName = skill.isEnabled ? skill.displayName : "\(skill.displayName).disabled"
        let destinationURL = globalURL.appendingPathComponent(destName)

        try fileSystem.createDirectoryIfNeeded(at: globalURL)
        try fileSystem.moveItem(from: skill.path, to: destinationURL)
    }

    func toggleEnableDisable(_ skill: Skill) throws {
        let parentDir = skill.path.deletingLastPathComponent()
        let currentName = skill.path.lastPathComponent

        if skill.isEnabled {
            // Disable: rename to .disabled
            let newName = "\(currentName).disabled"
            let newPath = parentDir.appendingPathComponent(newName)
            try fileSystem.moveItem(from: skill.path, to: newPath)
        } else {
            // Enable: remove .disabled suffix
            let newName = currentName.replacingOccurrences(of: ".disabled", with: "")
            let newPath = parentDir.appendingPathComponent(newName)
            try fileSystem.moveItem(from: skill.path, to: newPath)
        }
    }

    func deleteSkill(_ skill: Skill) throws {
        try fileSystem.removeItem(at: skill.path)
    }
}
