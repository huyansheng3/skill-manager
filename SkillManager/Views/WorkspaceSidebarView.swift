import SwiftUI

struct WorkspaceSidebarView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    @Binding var selectedWorkspace: Workspace?

    var body: some View {
        List {
            // Global sections - grouped by different global paths
            ForEach(viewModel.globalGroups) { group in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: viewModel.isGroupExpanded(group.path) ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 12)

                        Text(group.name)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(group.skills.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    }
                    .padding(.horizontal, 8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleGroupExpanded(group.path)
                    }

                    if viewModel.isGroupExpanded(group.path) {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(group.skills, id: \.id) { skill in
                                SkillRowView(
                                    skill: skill,
                                    isSelected: viewModel.selectedSkill?.id == skill.id
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedSkill = skill
                                    selectedWorkspace = nil
                                }
                                .id(skill.id)
                            }
                        }
                        .padding(.leading, 16)
                    }

                    // Show remove button for custom paths
                    if !["~/.claude/skills", "~/.codeflicker/skills"].contains(group.path) {
                        Button(action: {
                            viewModel.removeCustomGlobalPath(group.path)
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.caption)
                                Text("Remove this path")
                                    .font(.caption)
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 16)
                    }
                }
                .padding(.vertical, 4)
                .id("global-\(group.path)")
            }

            if !viewModel.workspaces.isEmpty {
                Divider()
                    .padding(.vertical, 4)
                    .id("workspaces-divider")

                HStack {
                    Text("Workspaces")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.workspaces.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    Button("Expand All") {
                        for workspace in viewModel.workspaces {
                            if !viewModel.isWorkspaceExpanded(workspace.id) {
                                viewModel.toggleWorkspaceExpanded(workspace.id)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .id("workspaces-header")

                ForEach(viewModel.workspaces) { workspace in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.isWorkspaceExpanded(workspace.id) ? "chevron.down" : "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 12)

                            Text(workspace.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Spacer()

                            let skillsCount = viewModel.filteredSkills(for: workspace.id).count
                            if skillsCount > 0 {
                                Text("\(skillsCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.secondary.opacity(0.2)))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.toggleWorkspaceExpanded(workspace.id)
                        }

                        if viewModel.isWorkspaceExpanded(workspace.id) {
                            Text(workspace.rootPath.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.leading, 16)

                            let skills = viewModel.filteredSkills(for: workspace.id)
                            if !skills.isEmpty {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(skills, id: \.id) { skill in
                                        SkillRowView(
                                            skill: skill,
                                            isSelected: viewModel.selectedSkill?.id == skill.id
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.selectedSkill = skill
                                            selectedWorkspace = workspace
                                        }
                                        .id(skill.id)
                                    }
                                }
                                .padding(.leading, 16)
                                .padding(.top, 2)
                            } else {
                                Text("No skills yet")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .id("workspace-\(workspace.id)")
                }
            }
        }
        .listStyle(.sidebar)
    }
}
