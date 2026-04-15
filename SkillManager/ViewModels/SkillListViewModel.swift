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