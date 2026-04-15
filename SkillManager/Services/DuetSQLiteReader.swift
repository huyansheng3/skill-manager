import Foundation
import SQLite3

// JSON structure for CodeFlicker workspace list
private struct DuetWorkspaceList: Codable {
    let workspaces: [DuetWorkspace]
}

private struct DuetWorkspace: Codable {
    let workspaceId: String
    let name: String
    let path: String
}

actor DuetSQLiteReader {
    private let defaultDBPath = "~/.codeflicker/data/codeflicker/duet.sqlite"

    func readWorkspaces() async -> [Workspace] {
        let expandedPath = (defaultDBPath as NSString).expandingTildeInPath
        let dbPath = expandedPath

        guard FileManager.default.fileExists(atPath: dbPath) else {
            return []
        }

        var db: OpaquePointer?
        if sqlite3_open(expandedPath, &db) != SQLITE_OK {
            if db != nil {
                sqlite3_close(db)
            }
            print("DuetSQLiteReader: Failed to open database at \(expandedPath)")
            return []
        }
        let database = db!
        defer { sqlite3_close(database) }

        // CodeFlicker stores workspace list in KV table
        let query = """
            SELECT value FROM KwaipilotKV WHERE key = 'duetWorkspaceList:v1';
        """

        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            print("DuetSQLiteReader: Failed to prepare query")
            return []
        }
        defer { sqlite3_finalize(statement) }

        var workspaces: [Workspace] = []

        if sqlite3_step(statement) == SQLITE_ROW {
            // Get BLOB data
            let blobPtr = sqlite3_column_blob(statement, 0)
            let blobLength = Int(sqlite3_column_bytes(statement, 0))

            let data = Data(bytes: blobPtr!, count: blobLength)

            // Parse JSON
            do {
                let decoder = JSONDecoder()
                let workspaceList = try decoder.decode(DuetWorkspaceList.self, from: data)

                for duetWorkspace in workspaceList.workspaces {
                    guard let uuid = UUID(uuidString: duetWorkspace.workspaceId) else {
                        continue
                    }

                    let rootPathURL = URL(fileURLWithPath: duetWorkspace.path)

                    // Workspace skills path: rootPath/.codeflicker/skills
                    let skillsPath = (duetWorkspace.path as NSString)
                        .appendingPathComponent(".codeflicker/skills")
                    let skillsURL = URL(fileURLWithPath: skillsPath)

                    let workspace = Workspace(
                        id: uuid,
                        name: duetWorkspace.name,
                        rootPath: rootPathURL,
                        skillsPath: skillsURL
                    )

                    workspaces.append(workspace)
                }
            } catch {
                print("DuetSQLiteReader: Failed to parse JSON: \(error.localizedDescription)")
                return []
            }
        }

        return workspaces
    }
}
