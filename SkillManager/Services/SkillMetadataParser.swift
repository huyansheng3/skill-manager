import Foundation

struct SkillMetadata {
    let name: String
    let description: String?
    let author: String?
}

actor SkillMetadataParser {
    private struct CacheEntry {
        let metadata: SkillMetadata
        let directoryModificationDate: Date?
    }

    private let fileSystem: FileSystem
    private var metadataCache: [String: CacheEntry] = [:]

    init(fileSystem: FileSystem = .shared) {
        self.fileSystem = fileSystem
    }

    func parseMetadata(from skillDir: URL) async -> SkillMetadata {
        let cacheKey = skillDir.path
        let dirModificationDate = await fileSystem.modificationDate(at: skillDir)

        if let cached = metadataCache[cacheKey],
           cached.directoryModificationDate == dirModificationDate {
            return cached.metadata
        }

        let name = skillDir.lastPathComponent.replacingOccurrences(of: ".disabled", with: "")
        let parsed = await parseMetadataUncached(name: name, skillDir: skillDir)

        metadataCache[cacheKey] = CacheEntry(
            metadata: parsed,
            directoryModificationDate: dirModificationDate
        )

        return parsed
    }

    private func parseMetadataUncached(name: String, skillDir: URL) async -> SkillMetadata {
        // Check for skill.json first (common format)
        let skillJSONURL = skillDir.appendingPathComponent("skill.json")
        if await fileSystem.fileExists(at: skillJSONURL) {
            if let content = await fileSystem.readTextFile(at: skillJSONURL),
               let data = content.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let description = json["description"] as? String
                let author = json["author"] as? String
                return SkillMetadata(name: name, description: description, author: author)
            } else {
                print("SkillMetadataParser: Failed to parse skill.json at \(skillJSONURL.path)")
            }
        }

        // Check for README.md
        let readmeURL = skillDir.appendingPathComponent("README.md")
        if await fileSystem.fileExists(at: readmeURL) {
            if let description = await extractDescription(from: readmeURL) {
                return SkillMetadata(name: name, description: description, author: nil)
            }
        }

        // Check for README
        let readmeNoExtURL = skillDir.appendingPathComponent("README")
        if await fileSystem.fileExists(at: readmeNoExtURL) {
            if let description = await extractDescription(from: readmeNoExtURL) {
                return SkillMetadata(name: name, description: description, author: nil)
            }
        }

        return SkillMetadata(name: name, description: nil, author: nil)
    }

    private func extractDescription(from url: URL) async -> String? {
        guard let content = await fileSystem.readTextFile(at: url) else {
            return nil
        }

        // Extract first paragraph as description
        let paragraphs = content.components(separatedBy: "\n\n")
        return paragraphs.first?
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
