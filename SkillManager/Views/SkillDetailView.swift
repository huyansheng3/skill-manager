import SwiftUI

struct SkillDetailView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    let skill: Skill

    @State private var showDeleteConfirm = false
    @State private var readmeContent: String?
    @State private var isLoadingReadme = false
    private let fileSystem = FileSystem.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(skill.displayName)
                        .font(.title)
                        .fontWeight(.bold)

                    if !skill.isEnabled {
                        HStack {
                            Text("Disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Capsule())
                    }
                }

                Spacer()
            }

            // Metadata
            VStack(alignment: .leading, spacing: 12) {
                if let author = skill.author, !author.isEmpty {
                    InfoRow(label: "Author", value: author)
                }

                if let description = skill.description, !description.isEmpty {
                    InfoRow(label: "Description", value: description)
                }

                InfoRow(label: "Location", value: locationName)
                InfoRow(label: "Path", value: skill.path.path, mono: true)
                InfoRow(label: "Size", value: formatSize(skill.size))
            }

            // README Preview
            if readmeContent != nil || isLoadingReadme {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("skill.md")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if isLoadingReadme {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let readmeContent = readmeContent {
                        ScrollView {
                            Text(readmeContent)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(6)
                    }
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
                .controlSize(.large)

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
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                if case .workspace = skill.location {
                    Button(action: {
                        Task { await viewModel.moveSkillToGlobal(skill) }
                    }) {
                        Text("Move to Global")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Divider()

                // Delete
                Button(role: .destructive, action: {
                    showDeleteConfirm = true
                }) {
                    Text("Delete Skill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding()
        .frame(minWidth: 300, maxWidth: .infinity)
        .background(Color(.textBackgroundColor))
        .alert("Delete Skill", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await viewModel.deleteSkill(skill) }
            }
        } message: {
            Text("Are you sure you want to delete '\(skill.displayName)'? This cannot be undone.")
        }
        .onAppear {
            loadReadme()
        }
    }

    private var locationName: String {
        switch skill.location {
        case .global:
            if skill.path.path.contains(".claude") {
                return "Global (Claude)"
            } else if skill.path.path.contains(".codeflicker") {
                return "Global (CodeFlicker)"
            } else {
                return "Global"
            }
        case .workspace:
            if let workspace = viewModel.workspaces.first(where: { $0.id == skill.workspaceId }) {
                return "Workspace: \(workspace.displayName)"
            } else {
                return "Workspace"
            }
        }
    }

    private func formatSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    private func loadReadme() {
        isLoadingReadme = true

        // Try skill.md first (used by Claude skills), then README.md, then README
        let candidates = [
            skill.path.appendingPathComponent("skill.md"),
            skill.path.appendingPathComponent("skill"),
            skill.path.appendingPathComponent("README.md"),
            skill.path.appendingPathComponent("README"),
            skill.path.appendingPathComponent("readme.md"),
            skill.path.appendingPathComponent("readme")
        ]

        Task {
            for candidate in candidates {
                if await fileSystem.fileExists(at: candidate) {
                    if let content = await fileSystem.readTextFile(at: candidate) {
                        await MainActor.run {
                            self.readmeContent = content
                            self.isLoadingReadme = false
                        }
                        return
                    }
                }
            }

            await MainActor.run {
                self.readmeContent = nil
                self.isLoadingReadme = false
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if mono {
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                Text(value)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
        }
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