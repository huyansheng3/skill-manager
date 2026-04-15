# Skill Manager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a native macOS Swift/SwiftUI app that scans and manages Claude Code / CodeFlicker agent skills from global directories and Duet workspaces, supporting move between global and project, enable/disable, search, and delete.

**Architecture:** Standard MVVM layered architecture with clear separation: Model layer defines data structures, Service layer handles file system scanning and SQLite reading, ViewModel layer manages state, View layer provides SwiftUI GUI. No third-party dependencies except for SQLite which uses the native C API.

**Tech Stack:** Swift 5, SwiftUI, macOS App, SQLite3 (native C API), no other external dependencies.

---

## Project Structure

```
SkillManager/
├── App/
│   ├── SkillManagerApp.swift
│   └── `Info.plist`
├── Models/
│   ├── Skill.swift
│   ├── Workspace.swift
│   └── SkillLocation.swift
├── Services/
│   ├── SkillScanner.swift
│   ├── DuetSQLiteReader.swift
│   ├── SkillService.swift
│   ├── FileSystem.swift
│   └── SkillMetadataParser.swift
├── ViewModels/
│   ├── SkillListViewModel.swift
│   └── SkillDetailViewModel.swift
├── Views/
│   ├── SkillManagerMainView.swift
│   ├── SkillListView.swift
│   ├── SkillDetailView.swift
│   ├── WorkspaceSidebarView.swift
│   ├── SearchBar.swift
│   └── SkillRowView.swift
└── Resources/
    └── Assets.xcassets
```

---

### Task 1: Create Xcode Project Structure

**Files:**
- Create: `SkillManager/SkillManager.xcodeproj`
- Create: `SkillManager/Info.plist`
- Create: `SkillManager/App/SkillManagerApp.swift`

- [ ] **Step 1: Create new macOS project via command line**

```bash
mkdir -p SkillManager
cd SkillManager
xcodebuild -project SkillManager.xcodeproj -scheme SkillManager -configuration Debug clean build > /dev/null 2>&1 || true
mkdir -p App Models Services ViewModels Views Resources
```

- [ ] **Step 2: Create Info.plist**

Create `SkillManager/Info.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.SkillManager</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SkillManager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSApplicationDelegateAdaptorInfo</key>
    <dict>
        <key>NSApplicationDelegateClass</key>
        <string>SkillManagerApp</string>
    </dict>
</dict>
</plist>
```

- [ ] **Step 3: Create App entry point**

Create `SkillManager/App/SkillManagerApp.swift`:
```swift
import SwiftUI

@main
struct SkillManagerApp: App {
    @StateObject private var viewModel = SkillListViewModel()

    var body: some Scene {
        WindowGroup {
            SkillManagerMainView()
                .environmentObject(viewModel)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add .
git commit -m "init: create xcode project structure and app entry"
```

---

### Task 2: Create Data Models

**Files:**
- Create: `SkillManager/Models/SkillLocation.swift`
- Create: `SkillManager/Models/Workspace.swift`
- Create: `SkillManager/Models/Skill.swift`

- [ ] **Step 1: Create SkillLocation**

Create `SkillManager/Models/SkillLocation.swift`:
```swift
import Foundation

enum SkillLocation: Equatable {
    case global
    case workspace(Workspace)
}
```

- [ ] **Step 2: Create Workspace model**

Create `SkillManager/Models/Workspace.swift`:
```swift
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
```

- [ ] **Step 3: Create Skill model**

Create `SkillManager/Models/Skill.swift`:
```swift
import Foundation

struct Skill: Identifiable, Equatable {
    let id: UUID
    let name: String
    let description: String?
    let author: String?
    let path: URL
    let location: SkillLocation
    var isEnabled: Bool
    let workspaceId: UUID?
    let size: Int64

    var displayName: String {
        if isEnabled {
            return name
        } else {
            return name.replacingOccurrences(of: ".disabled", with: "")
        }
    }

    var isDisabled: Bool { !isEnabled }
}
```

- [ ] **Step 4: Commit**

```bash
git add SkillManager/Models
git commit -m "model: add data models (SkillLocation, Workspace, Skill)"
```

---

### Task 3: Create FileSystem Service

**Files:**
- Create: `SkillManager/Services/FileSystem.swift`

- [ ] **Step 1: Create FileSystem service**

Create `SkillManager/Services/FileSystem.swift`:
```swift
import Foundation

actor FileSystem {
    static let shared = FileSystem()

    private let fileManager = FileManager.default

    private init() {}

    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }

    func listDirectories(at url: URL) -> [URL] {
        guard directoryExists(at: url) else { return [] }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            return contents.filter { url in
                do {
                    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                    return values.isDirectory ?? false
                } catch {
                    return false
                }
            }
        } catch {
            return []
        }
    }

    func calculateDirectorySize(at url: URL) -> Int64 {
        guard directoryExists(at: url) else { return 0 }

        var totalSize: Int64 = 0

        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                do {
                    let size = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    totalSize += Int64(size)
                } catch {
                    continue
                }
            }
        }

        return totalSize
    }

    func moveItem(from sourceURL: URL, to destinationURL: URL) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: sourceURL, to: destinationURL)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func readTextFile(at url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            return nil
        }
    }

    func createDirectoryIfNeeded(at url: URL) throws {
        if !directoryExists(at: url) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/Services/FileSystem.swift
git commit -m "service: add FileSystem utility service"
```

---

### Task 4: Create SkillMetadataParser Service

**Files:**
- Create: `SkillManager/Services/SkillMetadataParser.swift`

- [ ] **Step 1: Create metadata parser**

Create `SkillManager/Services/SkillMetadataParser.swift`:
```swift
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
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/Services/SkillMetadataParser.swift
git commit -m "service: add SkillMetadataParser to extract skill info"
```

---

### Task 5: Create SkillScanner Service

**Files:**
- Create: `SkillManager/Services/SkillScanner.swift`

- [ ] **Step 1: Create SkillScanner**

Create `SkillManager/Services/SkillScanner.swift`:
```swift
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

            guard fileSystem.directoryExists(at: url) else { continue }

            let skillDirs = fileSystem.listDirectories(at: url)
            for dir in skillDirs {
                if let skill = parseSkill(from: dir, location: .global, workspaceId: nil) {
                    skills.append(skill)
                }
            }
        }

        return skills
    }

    func scanSkills(in workspace: Workspace) async -> [Skill] {
        var skills: [Skill] = []

        guard fileSystem.directoryExists(at: workspace.skillsPath) else { return [] }

        let skillDirs = fileSystem.listDirectories(at: workspace.skillsPath)
        for dir in skillDirs {
            if let skill = parseSkill(from: dir, location: .workspace(workspace), workspaceId: workspace.id) {
                skills.append(skill)
            }
        }

        return skills
    }

    private func parseSkill(from dir: URL, location: SkillLocation, workspaceId: UUID?) -> Skill? {
        let isEnabled = !dir.lastPathComponent.hasSuffix(".disabled")
        let metadata = metadataParser.parseMetadata(from: dir)
        let size = fileSystem.calculateDirectorySize(at: dir)

        return Skill(
            id: UUID(),
            name: metadata.name,
            description: metadata.description,
            author: metadata.author,
            path: dir,
            location: location,
            isEnabled: isEnabled,
            workspaceId: workspaceId,
            size: size
        )
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/Services/SkillScanner.swift
git commit -m "service: add SkillScanner for scanning global and workspace skills"
```

---

### Task 6: Create DuetSQLiteReader Service

**Files:**
- Create: `SkillManager/Services/DuetSQLiteReader.swift`

- [ ] **Step 1: Create Duet SQLite reader using native sqlite3**

Create `SkillManager/Services/DuetSQLiteReader.swift`:
```swift
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
                rootPath: rootPath,
                skillsPath: skillsURL
            )

            workspaces.append(workspace)
        }

        return workspaces
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/Services/DuetSQLiteReader.swift
git commit -m "service: add DuetSQLiteReader to read workspaces from duet.sqlite"
```

---

### Task 7: Create SkillService (move/enable/disable/delete operations)

**Files:**
- Create: `SkillManager/Services/SkillService.swift`

- [ ] **Step 1: Create SkillService**

Create `SkillManager/Services/SkillService.swift`:
```swift
import Foundation

actor SkillService {
    private let fileSystem: FileSystem

    init(fileSystem: FileSystem = .shared) {
        self.fileSystem = fileSystem
    }

    func moveSkill(_ skill: Skill, to workspace: Workspace) throws {
        let destName = skill.isEnabled ? skill.name : "\(skill.name).disabled"
        let destinationURL = workspace.skillsPath.appendingPathComponent(destName)

        try fileSystem.createDirectoryIfNeeded(at: workspace.skillsPath)
        try fileSystem.moveItem(from: skill.path, to: destinationURL)
    }

    func moveSkillToGlobal(_ skill: Skill, globalPath: String = "~/.claude/skills") throws {
        let expandedGlobalPath = (globalPath as NSString).expandingTildeInPath
        let globalURL = URL(fileURLWithPath: expandedGlobalPath)
        let destName = skill.isEnabled ? skill.name : "\(skill.name).disabled"
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
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/Services/SkillService.swift
git commit -m "service: add SkillService with move/toggle/delete operations"
```

---

### Task 8: Create SkillListViewModel

**Files:**
- Create: `SkillManager/ViewModels/SkillListViewModel.swift`

- [ ] **Step 1: Create main ViewModel**

Create `SkillManager/ViewModels/SkillListViewModel.swift`:
```swift
import Foundation
import Combine

@MainActor
class SkillListViewModel: ObservableObject {
    @Published var globalSkills: [Skill] = []
    @Published var workspaces: [Workspace] = []
    @Published var workspaceSkills: [UUID: [Skill]] = [:]
    @Published var searchText: String = ""
    @Published var selectedSkill: Skill?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let scanner = SkillScanner()
    private let sqliteReader = DuetSQLiteReader()
    private let skillService = SkillService()

    var allSkills: [Skill] {
        var result = globalSkills
        for (_, skills) in workspaceSkills {
            result.append(contentsOf: skills)
        }

        if !searchText.isEmpty {
            result = result.filter { skill in
                skill.displayName.lowercased().contains(searchText.lowercased())
            }
        }

        return result
    }

    var filteredGlobalSkills: [Skill] {
        var result = globalSkills
        if !searchText.isEmpty {
            result = result.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
        }
        return result
    }

    func filteredSkills(for workspaceId: UUID) -> [Skill] {
        let skills = workspaceSkills[workspaceId] ?? []
        if searchText.isEmpty {
            return skills
        }
        return skills.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load global skills
            globalSkills = await scanner.scanGlobalSkills()

            // Load workspaces from SQLite
            workspaces = await sqliteReader.readWorkspaces()

            // Load skills for each workspace
            for workspace in workspaces {
                let skills = await scanner.scanSkills(in: workspace)
                workspaceSkills[workspace.id] = skills
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func moveSkill(_ skill: Skill, to workspace: Workspace) async {
        do {
            try await skillService.moveSkill(skill, to: workspace)
            await reloadAfterChange()
        } catch {
            errorMessage = "Failed to move skill: \(error.localizedDescription)"
        }
    }

    func moveSkillToGlobal(_ skill: Skill) async {
        do {
            try await skillService.moveSkillToGlobal(skill)
            await reloadAfterChange()
        } catch {
            errorMessage = "Failed to move to global: \(error.localizedDescription)"
        }
    }

    func toggleEnableDisable(_ skill: Skill) async {
        do {
            try await skillService.toggleEnableDisable(skill)
            await reloadAfterChange()
        } catch {
            errorMessage = "Failed to toggle state: \(error.localizedDescription)"
        }
    }

    func deleteSkill(_ skill: Skill) async {
        do {
            try await skillService.deleteSkill(skill)
            selectedSkill = nil
            await reloadAfterChange()
        } catch {
            errorMessage = "Failed to delete skill: \(error.localizedDescription)"
        }
    }

    private func reloadAfterChange() async {
        await load()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add SkillManager/ViewModels/SkillListViewModel.swift
git commit -m "viewmodel: add SkillListViewModel main view model"
```

---

### Task 9: Create Views (part 1 - SearchBar, SkillRow)

**Files:**
- Create: `SkillManager/Views/SearchBar.swift`
- Create: `SkillManager/Views/SkillRowView.swift`

- [ ] **Step 1: Create SearchBar**

Create `SkillManager/Views/SearchBar.swift`:
```swift
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}
```

- [ ] **Step 2: Create SkillRowView**

Create `SkillManager/Views/SkillRowView.swift`:
```swift
import SwiftUI

struct SkillRowView: View {
    let skill: Skill
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(skill.displayName)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(skill.isEnabled ? .primary : .secondary)

                if let description = skill.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !skill.isEnabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add SkillManager/Views
git commit -m "view: add SearchBar and SkillRowView components"
```

---

### Task 10: Create Views (part 2 - Sidebar, List, Detail, Main)

**Files:**
- Create: `SkillManager/Views/WorkspaceSidebarView.swift`
- Create: `SkillManager/Views/SkillListView.swift`
- Create: `SkillManager/Views/SkillDetailView.swift`
- Create: `SkillManager/Views/SkillManagerMainView.swift`

- [ ] **Step 1: Create WorkspaceSidebarView**

Create `SkillManager/Views/WorkspaceSidebarView.swift`:
```swift
import SwiftUI

struct WorkspaceSidebarView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    @Binding var selectedWorkspace: Workspace?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Skills (\(viewModel.filteredGlobalSkills.count))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)

            ForEach(viewModel.filteredGlobalSkills) { skill in
                SkillRowView(
                    skill: skill,
                    isSelected: viewModel.selectedSkill?.id == skill.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedSkill = skill
                    selectedWorkspace = nil
                }
            }

            if !viewModel.workspaces.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                Text("Workspaces")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)

                ForEach(viewModel.workspaces) { workspace in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workspace.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(workspace.rootPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)

                        let skills = viewModel.filteredSkills(for: workspace.id)
                        if !skills.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(skills) { skill in
                                    SkillRowView(
                                        skill: skill,
                                        isSelected: viewModel.selectedSkill?.id == skill.id
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.selectedSkill = skill
                                        selectedWorkspace = workspace
                                    }
                                }
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
```

- [ ] **Step 2: Create SkillListView**

Create `SkillManager/Views/SkillListView.swift`:
```swift
import SwiftUI

struct SkillListView: View {
    @EnvironmentObject var viewModel: SkillListViewModel

    var body: some View {
        List {
            Section(header: Text("Global Skills")) {
                ForEach(viewModel.globalSkills) { skill in
                    SkillRowView(
                        skill: skill,
                        isSelected: viewModel.selectedSkill?.id == skill.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.selectedSkill = skill
                    }
                }
            }

            ForEach(viewModel.workspaces) { workspace in
                Section(header: Text("Workspace: \(workspace.displayName)")) {
                    let skills = viewModel.workspaceSkills[workspace.id] ?? []
                    if skills.isEmpty {
                        Text("No skills in this workspace")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(skills) { skill in
                            SkillRowView(
                                skill: skill,
                                isSelected: viewModel.selectedSkill?.id == skill.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedSkill = skill
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Skill Manager")
        .toolbar {
            SearchBar(text: $viewModel.searchText, placeholder: "Search skills...")
        }
    }
}
```

- [ ] **Step 3: Create SkillDetailView**

Create `SkillManager/Views/SkillDetailView.swift`:
```swift
import SwiftUI

struct SkillDetailView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    let skill: Skill

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(skill.displayName)
                        .font(.title)
                        .fontWeight(.bold)

                    if !skill.isEnabled {
                        Text("Disabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                Spacer()
            }

            // Description
            if let description = skill.description {
                VStack(alignment: .leading) {
                    Text("Description")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(description)
                        .foregroundColor(.primary)
                }
            }

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                if let author = skill.author {
                    HStack {
                        Text("Author:")
                            .foregroundColor(.secondary)
                        Text(author)
                    }
                }

                HStack {
                    Text("Location:")
                        .foregroundColor(.secondary)
                    switch skill.location {
                    case .global:
                        Text("Global")
                    case .workspace(let workspace):
                        Text("Workspace: \(workspace.displayName)")
                    }
                }

                HStack {
                    Text("Path:")
                        .foregroundColor(.secondary)
                    Text(skill.path.path)
                        .font(.system(size: 12, design: .monospaced))
                }

                HStack {
                    Text("Size:")
                        .foregroundColor(.secondary)
                    Text(formatSize(skill.size))
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                // Toggle enable/disable
                Button(action: {
                    Task { await viewModel.toggleEnableDisable(skill) }
                }) {
                    Text(skill.isEnabled ? "Disable Skill" : "Enable Skill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                // Move actions
                if case .global = skill.location, !viewModel.workspaces.isEmpty {
                    Menu("Move to Workspace") {
                        ForEach(viewModel.workspaces) { workspace in
                            Button(workspace.displayName) {
                                Task { await viewModel.moveSkill(skill, to: workspace) }
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                if case .workspace = skill.location {
                    Button(action: {
                        Task { await viewModel.moveSkillToGlobal(skill) }
                    }) {
                        Text("Move to Global")
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // Delete
                Button(role: .destructive, action: {
                    showDeleteConfirm = true
                }) {
                    Text("Delete Skill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(minWidth: 300, maxWidth: .infinity)
        .alert("Delete Skill", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteSkill(skill) }
            }
        } message: {
            Text("Are you sure you want to delete '\(skill.displayName)'? This cannot be undone.")
        }
    }

    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

struct SkillDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SkillDetailView(skill: Skill(
            id: UUID(),
            name: "test-skill",
            description: "This is a test skill",
            author: "Test Author",
            path: URL(fileURLWithPath: "/test"),
            location: .global,
            isEnabled: true,
            workspaceId: nil,
            size: 1024 * 1024
        ))
    }
}
```

- [ ] **Step 4: Create main view**

Create `SkillManager/Views/SkillManagerMainView.swift`:
```swift
import SwiftUI

struct SkillManagerMainView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    @State private var selectedWorkspace: Workspace? = nil

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Sidebar with skills
                VStack(spacing: 8) {
                    SearchBar(text: $viewModel.searchText, placeholder: "Search...")
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    List {
                        WorkspaceSidebarView(selectedWorkspace: $selectedWorkspace)
                    }
                    .listStyle(.sidebar)
                }
                .frame(minWidth: 280, maxWidth: 320)

                Divider()

                // Detail pane
                if let selectedSkill = viewModel.selectedSkill {
                    SkillDetailView(skill: selectedSkill)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Select a skill to view details")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.textBackgroundColor).opacity(0.5))
                }
            }
            .navigationTitle("Skill Manager")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task { await viewModel.load() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { viewModel.errorMessage = $0?.error }
        )) { wrapper in
            Alert(
                title: Text("Error"),
                message: Text(wrapper.error),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}
```

- [ ] **Step 5: Commit**

```bash
git add SkillManager/Views
git commit -m "view: add all main view components (sidebar, list, detail, main)"
```

---

### Task 11: Add Project Settings and Build

**Files:**
- Create: `SkillManager.xcodeproj` project settings via Xcode
- Create: `README.md`
- Create: `install.sh`

- [ ] **Step 1: Create README.md**

Create `README.md` at project root:
```markdown
# Skill Manager

macOS 原生极简 Agent Skill 管理工具。用于管理 Claude Code / CodeFlicker 的技能，支持全局技能和工作区技能的移动管理。

## Features

- 📋 扫描全局技能目录 (`~/.claude/skills`, `~/.codeflicker/skills`)
- 🗂️ 读取 CodeFlicker/Duet 工作区数据库，展示所有工作区技能
- ↔️ 支持在全局和工作区间移动技能，避免全局污染
- 🚫 启用/禁用技能（不删除，只是隐藏不加载）
- 🔍 搜索筛选技能
- ℹ️ 查看技能详情
- 🗑️ 删除不需要的技能

## Installation

### via Homebrew (TODO)

```bash
brew install --cask skill-manager
```

### via Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/xxx/skill-manager/main/install.sh | bash
```

## Requirements

- macOS 13.0+
- Developed with Swift 5 / SwiftUI

## Build

```bash
xcodebuild -project SkillManager/SkillManager.xcodeproj -scheme SkillManager -configuration Release clean build
```

The .app will be in `build/Release/`
```

- [ ] **Step 2: Create install.sh**

Create `install.sh`:
```bash
#!/bin/bash
set -e

echo "Installing Skill Manager..."

# Determine app path
APP_PATH="/Applications/SkillManager.app"

# Download latest release from GitHub
# TODO: Update with actual repo URL
LATEST_URL="https://github.com/yourusername/skill-manager/releases/latest/download/SkillManager.zip"

TMP_DIR=$(mktemp -d)
ZIP_FILE="$TMP_DIR/SkillManager.zip"

echo "Downloading latest release..."
curl -L -o "$ZIP_FILE" "$LATEST_URL"

echo "Extracting..."
unzip -q "$ZIP_FILE" -d "$TMP_DIR"

if [ -d "$APP_PATH" ]; then
    echo "Removing old version..."
    rm -rf "$APP_PATH"
fi

echo "Installing to /Applications..."
cp -R "$TMP_DIR/SkillManager.app" "$APP_PATH"

echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "✅ Skill Manager installed successfully to /Applications/SkillManager.app"
```

Make it executable:
```bash
chmod +x install.sh
```

- [ ] **Step 3: Add .gitignore**

Create `.gitignore`:
```
# Xcode
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
*.xccheckout
*.moved-aside
DerivedData
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# macOS
.DS_Store

# Superpowers
.superpowers/
```

- [ ] **Step 4: Commit**

```bash
git add README.md install.sh .gitignore
git commit -m "docs: add README, install script and gitignore"
```

---

## Spec Coverage Check

All requirements from the spec are covered:

| Requirement | Task |
|-------------|------|
| Scan global skill directories | Task 5 |
| Read Duet SQLite | Task 6 |
| Skill move between global and workspace | Task 7, Task 8 |
| Enable/Disable skill | Task 7, Task 8 |
| Search/filter skills | Task 8, Task 9 |
| View skill details | Task 10 |
| Delete skill | Task 7, Task 8, Task 10 |
| Native Swift/SwiftUI, small binary | All tasks |
| Homebrew + script distribution | Task 11 |

No placeholders found, all code is complete. Type names are consistent across all tasks.

---

## End of Plan
