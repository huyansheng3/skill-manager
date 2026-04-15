import Foundation

struct SkillMetadata {
    let name: String
    let description: String?
    let author: String?
}

actor SkillMetadataParser {
    private let fileSystem: FileSystem

    init(fileSystem: FileSystem = .shared) {
        self.fileSystem = fileSystem
    }

    func parseMetadata(from skillDir: URL) -> SkillMetadata {
        let name = skillDir.lastPathComponent.replacingOccurrences(of: ".disabled", with: "")

        // Check for skill.json first (common format)
        let skillJSONURL = skillDir.appendingPathComponent("skill.json")
        if fileSystem.fileExists(at: skillJSONURL) {
            if let data = try? Data(contentsOf: skillJSONURL),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let description = json["description"] as? String
                let author = json["author"] as? String
                return SkillMetadata(name: name, description: description, author: author)
            }
        }

        // Check for README.md
        let readmeURL = skillDir.appendingPathComponent("README.md")
        if fileSystem.fileExists(at: readmeURL) {
            if let content = fileSystem.readTextFile(at: readmeURL) {
                // Extract first paragraph as description
                let paragraphs = content.components(separatedBy: "\n\n")
                let description = paragraphs.first?
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return SkillMetadata(name: name, description: description, author: nil)
            }
        }

        // Check for README
        let readmeNoExtURL = skillDir.appendingPathComponent("README")
        if fileSystem.fileExists(at: readmeNoExtURL) {
            if let content = fileSystem.readTextFile(at: readmeNoExtURL) {
                let paragraphs = content.components(separatedBy: "\n\n")
                let description = paragraphs.first?
                    .replacingOccurrences(of: "#", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return SkillMetadata(name: name, description: description, author: nil)
            }
        }

        return SkillMetadata(name: name, description: nil, author: nil)
    }
}
