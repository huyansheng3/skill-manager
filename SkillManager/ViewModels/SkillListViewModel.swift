import Foundation
import Combine

@MainActor
class SkillListViewModel: ObservableObject {
    @Published var globalSkills: [Skill] = []
    @Published var workspaces: [Workspace] = []
    @Published var workspaceSkills: [String: [Skill]] = [:]
    @Published var searchText: String = ""
    @Published var selectedSkill: Skill?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var expandedGroups: Set<String> = []
    @Published var expandedWorkspaces: Set<String> = []

    private let scanner: SkillScanner
    private let sqliteReader: DuetSQLiteReader
    private let skillService: SkillService

    public init(
        scanner: SkillScanner = SkillScanner(),
        sqliteReader: DuetSQLiteReader = DuetSQLiteReader(),
        skillService: SkillService = SkillService()
    ) {
        self.scanner = scanner
        self.sqliteReader = sqliteReader
        self.skillService = skillService
        // By default expand all groups on first load
        expandAllGroups()
    }

    struct GlobalGroup: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let skills: [Skill]
    }

    var globalGroups: [GlobalGroup] {
        let groups = scanner.groupGlobalSkills(globalSkills)

        return groups.compactMap { (name, path, skills) in
            if searchText.isEmpty {
                return GlobalGroup(name: name, path: path, skills: skills)
            } else {
                let filtered = skills.filter {
                    $0.displayName.lowercased().contains(searchText.lowercased())
                }
                return filtered.isEmpty ? nil : GlobalGroup(name: name, path: path, skills: filtered)
            }
        }
    }

    func expandAllGroups() {
        // Auto-expand all groups on startup
        let paths = scanner.allGlobalPaths()
        expandedGroups = Set(paths)
        // Auto-expand all workspaces
        expandedWorkspaces = Set(workspaces.map { $0.id })
    }

    func toggleGroupExpanded(_ path: String) {
        if expandedGroups.contains(path) {
            expandedGroups.remove(path)
        } else {
            expandedGroups.insert(path)
        }
    }

    func isGroupExpanded(_ path: String) -> Bool {
        return expandedGroups.contains(path)
    }

    func toggleWorkspaceExpanded(_ id: String) {
        if expandedWorkspaces.contains(id) {
            expandedWorkspaces.remove(id)
        } else {
            expandedWorkspaces.insert(id)
        }
    }

    func isWorkspaceExpanded(_ id: String) -> Bool {
        return expandedWorkspaces.contains(id)
    }

    func removeCustomGlobalPath(_ path: String) {
        scanner.removeCustomGlobalPath(path)
        Task { await load() }
    }

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

    func filteredSkills(for workspaceId: String) -> [Skill] {
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

            // Load skills for each workspace in parallel
            await withTaskGroup(of: (String, [Skill]?).self) { group in
                for workspace in workspaces {
                    group.addTask { [self] in
                        let skills = await self.scanner.scanSkills(in: workspace)
                        return (workspace.id, skills)
                    }
                }
                for await (id, skills) in group {
                    if let skills = skills {
                        workspaceSkills[id] = skills
                    }
                }
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

    func addCustomGlobalPath(_ path: String) async {
        scanner.addCustomGlobalPath(path)
        await load()
    }

    private func reloadAfterChange() async {
        await load()
    }
}