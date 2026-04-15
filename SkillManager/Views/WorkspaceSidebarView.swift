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

                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(group.skills) { skill in
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
                    }
                    .padding(.leading, 4)
                }
                .padding(.vertical, 8)
            }

            if !viewModel.workspaces.isEmpty {
                Divider()
                    .padding(.vertical, 4)

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
                }
                .padding(.horizontal, 8)

                ForEach(viewModel.workspaces) { workspace in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workspace.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

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
                            .padding(.leading, 4)
                        } else {
                            Text("No skills yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedWorkspace?.id == workspace.id ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                }
            }
        }
        .listStyle(.sidebar)
    }
}