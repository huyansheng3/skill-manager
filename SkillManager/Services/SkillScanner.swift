import Foundation

actor SkillScanner {
    private let fileSystem: FileSystem
    private let metadataParser: SkillMetadataParser

    private let defaultGlobalPaths: [String] = [
        "~/.claude/skills",
        "~/.codeflicker/skills"
    ]

    init(fileSystem: FileSystem = .shared, metadataParser: SkillMetadataParser = .init()) {
        self.fileSystem = fileSystem
        self.metadataParser = metadataParser
    }

    func scanGlobalSkills() async -> [Skill] {
        var skills: [Skill] = []

        for path in defaultGlobalPaths {
            let expandedPath = (path as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)

            guard await fileSystem.directoryExists(at: url) else { continue }

            let skillDirs = await fileSystem.listDirectories(at: url)
            for dir in skillDirs {
                if let skill = parseSkill(from: dir, location: .global) {
                    skills.append(skill)
                }
            }
        }

        return skills
    }

    func scanSkills(in workspace: Workspace) async -> [Skill] {
        var skills: [Skill] = []

        guard await fileSystem.directoryExists(at: workspace.skillsPath) else { return [] }

        let skillDirs = await fileSystem.listDirectories(at: workspace.skillsPath)
        for dir in skillDirs {
            if let skill = parseSkill(from: dir, location: .workspace(workspace.id)) {
                skills.append(skill)
            }
        }

        return skills
    }

    private func parseSkill(from dir: URL, location: SkillLocation) -> Skill? {
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