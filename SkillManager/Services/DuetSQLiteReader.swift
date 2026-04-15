import Foundation
import SQLite3

actor DuetSQLiteReader {
    private let defaultDBPath = "~/.codeflicker/data/codeflicker/duet.sqlite"

    func readWorkspaces() async -> [Workspace] {
        let expandedPath = (defaultDBPath as NSString).expandingTildeInPath
        let dbPath = expandedPath

        guard FileManager.default.fileExists(atPath: dbPath) else {
            return []
        }

        var db: OpaquePointer?
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_close(db) }

        let query = """
            SELECT id, name, root_path FROM workspaces WHERE deleted_at IS NULL ORDER BY created_at DESC;
        """

        var workspaces: [Workspace] = []
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            let idBytes = sqlite3_column_text(statement, 0)
            let nameBytes = sqlite3_column_text(statement, 1)
            let rootPathBytes = sqlite3_column_text(statement, 2)

            guard let idBytes = idBytes,
                  let rootPathBytes = rootPathBytes else { continue }

            let idString = String(cString: idBytes)
            let name = nameBytes != nil ? String(cString: nameBytes) : ""
            let rootPath = String(cString: rootPathBytes)

            guard let uuid = UUID(uuidString: idString) else { continue }

            // Workspace skills path: rootPath/.codeflicker/skills
            let skillsPath = (rootPath as NSString)
                .appendingPathComponent(".codeflicker/skills")
            let skillsURL = URL(fileURLWithPath: skillsPath)

            let workspace = Workspace(
                id: uuid,
                name: name,
                rootPath: URL(fileURLWithPath: rootPath),
                skillsPath: skillsURL
            )

            workspaces.append(workspace)
        }

        return workspaces
    }
}
