import Foundation

actor SkillScanner {
    private let fileSystem: FileSystem
    private let metadataParser: SkillMetadataParser

    init(fileSystem: FileSystem = .shared, metadataParser: SkillMetadataParser = .init()) {
        self.fileSystem = fileSystem
        self.metadataParser = metadataParser
    }

    func scanGlobalSkills() async -> [Skill] {
        var skills: [Skill] = []

        for path in allGlobalPaths() {
            let expandedPath = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)

            guard await fileSystem.directoryExists(at: url) else { continue }

            let skillDirs = await fileSystem.listDirectories(at: url)
            for dir in skillDirs {
                if let skill = await parseSkill(from: dir, location: .global) {
                    skills.append(skill)
                }
            }
        }

        return skills
    }

    nonisolated func groupGlobalSkills(_ skills: [Skill]) -> [(name: String, path: String, skills: [Skill])] {
        var groups: [(name: String, path: String, skills: [Skill])] = []

        // Add default paths with friendly names
        let defaultPaths = [
            ("Claude", "~/.claude/skills"),
            ("CodeFlicker", "~/.codeflicker/skills")
        ]

        for (name, path) in defaultPaths {
            let expandedPath = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            let groupSkills = skills.filter { $0.path.deletingLastPathComponent() == url }
            if !groupSkills.isEmpty || allGlobalPaths().contains(path) {
                groups.append((name, path, groupSkills))
            }
        }

        // Add custom paths
        let customPaths = getCustomGlobalPaths()
        for (index, path) in customPaths.enumerated() {
            let expandedPath = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)
            let groupSkills = skills.filter { $0.path.deletingLastPathComponent() == url }
            let name = URL(fileURLWithPath: expandedPath).lastPathComponent
            groups.append((name, path, groupSkills))
        }

        return groups
    }

    // Make these non-isolated because they only access UserDefaults, no actor state
    nonisolated func getCustomGlobalPaths() -> [String] {
        let defaults = UserDefaults.standard
        return defaults.stringArray(forKey: "customGlobalPaths") ?? []
    }

    nonisolated func addCustomGlobalPath(_ path: String) {
        var paths = getCustomGlobalPaths()
        if !paths.contains(path) {
            paths.append(path)
            let defaults = UserDefaults.standard
            defaults.set(paths, forKey: "customGlobalPaths")
        }
    }

    nonisolated func removeCustomGlobalPath(_ path: String) {
        var paths = getCustomGlobalPaths()
        paths.removeAll { $0 == path }
        let defaults = UserDefaults.standard
        defaults.set(paths, forKey: "customGlobalPaths")
    }

    nonisolated func allGlobalPaths() -> [String] {
        return [
            "~/.claude/skills",
            "~/.codeflicker/skills"
        ] + getCustomGlobalPaths()
    }

    func scanSkills(in workspace: Workspace) async -> [Skill] {
        var skills: [Skill] = []

        guard await fileSystem.directoryExists(at: workspace.skillsPath) else { return [] }

        let skillDirs = await fileSystem.listDirectories(at: workspace.skillsPath)
        for dir in skillDirs {
            if let skill = await parseSkill(from: dir, location: .workspace(workspace.id)) {
                skills.append(skill)
            }
        }

        return skills
    }

    private func parseSkill(from dir: URL, location: SkillLocation) async -> Skill? {
        let isEnabled = !dir.lastPathComponent.hasSuffix(".disabled")
        let metadata = await metadataParser.parseMetadata(from: dir)
        let size = await fileSystem.calculateDirectorySize(at: dir)

        return Skill(
            id: UUID(),
            name: metadata.name,
            description: metadata.description,
            author: metadata.author,
            path: dir,
            location: location,
            isEnabled: isEnabled,
            size: size
        )
    }
}