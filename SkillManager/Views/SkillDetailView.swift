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
                    case .workspace(_):
                        Text("Workspace")
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
            description: "This is a test skill for managing Claude Code / CodeFlicker agent skills.",
            author: "Test Author",
            path: URL(fileURLWithPath: "/test"),
            location: .global,
            isEnabled: true,
            size: 1024 * 1024
        ))
        .environmentObject(SkillListViewModel())
    }
}