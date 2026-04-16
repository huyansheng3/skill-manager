import SwiftUI

struct SkillDetailView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    let skill: Skill

    @State private var showDeleteConfirm = false
    @State private var readmeContent: String?
    @State private var isLoadingReadme = false
    private let fileSystem = FileSystem.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        // Skill Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)

                            Image(systemName: "wrench.and.screwdriver")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(skill.displayName)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            if !skill.isEnabled {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.6))
                                        .frame(width: 6, height: 6)
                                    Text("Disabled")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(Capsule())
                            }
                        }

                        Spacer()
                    }
                }
                .padding(.bottom, 8)

                // Metadata Card
                VStack(alignment: .leading, spacing: 14) {
                    Text("Details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)

                    VStack(alignment: .leading, spacing: 14) {
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
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.controlBackgroundColor))
                    )
                }

                // README Preview
                if readmeContent != nil || isLoadingReadme {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 12, weight: .semibold))
                            Text("skill.md")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.secondary)

                        if isLoadingReadme {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.textBackgroundColor))
                            )
                        } else if let readmeContent = readmeContent {
                            ScrollView {
                                Text(readmeContent)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(16)
                            }
                            .frame(maxHeight: 280)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.textBackgroundColor))
                            )
                        }
                    }
                }

                Spacer()
                    .frame(height: 8)

                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)

                    VStack(spacing: 12) {
                        // Toggle enable/disable
                        Button(action: {
                            Task { await viewModel.toggleEnableDisable(skill) }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: skill.isEnabled ? "eye.slash" : "eye")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(skill.isEnabled ? "Disable Skill" : "Enable Skill")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: skill.isEnabled
                                                ? [Color.orange.opacity(0.9), Color.orange.opacity(0.7)]
                                                : [Color.green.opacity(0.9), Color.green.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .foregroundColor(.white)
                            .shadow(color: (skill.isEnabled ? Color.orange : Color.green).opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)

                        // Move actions
                        if case .global = skill.location, !viewModel.workspaces.isEmpty {
                            Menu {
                                ForEach(viewModel.workspaces) { workspace in
                                    Button(action: {
                                        Task { await viewModel.moveSkill(skill, to: workspace) }
                                    }) {
                                        HStack {
                                            Image(systemName: "folder")
                                            Text(workspace.displayName)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "tray.and.arrow.down")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Move to Workspace")
                                        .font(.system(size: 15, weight: .semibold))
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                                )
                                .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }

                        if case .workspace = skill.location {
                            Button(action: {
                                Task { await viewModel.moveSkillToGlobal(skill) }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Move to Global")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                                )
                                .foregroundColor(.purple)
                            }
                            .buttonStyle(.plain)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        // Delete
                        Button(role: .destructive, action: {
                            showDeleteConfirm = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Skill")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.red.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.4), lineWidth: 1.5)
                            )
                            .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .frame(minWidth: 340, maxWidth: .infinity)
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
        .onChange(of: skill.id) { _ in
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
        // Reset state immediately when skill changes
        readmeContent = nil
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
