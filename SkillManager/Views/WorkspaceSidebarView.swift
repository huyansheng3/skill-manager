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

                        Text(workspace.rootPath.path)
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