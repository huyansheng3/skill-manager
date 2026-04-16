import SwiftUI

struct SkillDetailView: View {
    @EnvironmentObject var viewModel: SkillListViewModel
    let skill: Skill

    @State private var showDeleteConfirm = false
    @State private var readmeContent: String?
    @State private var isReadmeTruncated = false
    @State private var isLoadingReadme = false
    @State private var readmeLoadTask: Task<Void, Never>?
    @State private var lastReadmeLoadDate: Date = .distantPast
    private let readmeDebounceInterval: TimeInterval = 0.12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
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

                    VStack(alignment: .leading, spacing: 3) {
                        Text(skill.displayName)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("\(locationName) · \(formatSize(skill.size))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)

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
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }

                    Spacer()
                }
            }
            .padding(.bottom, 2)

            // Path
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Text(skill.path.path)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )

            // README Preview - Main content area
            VStack(alignment: .leading, spacing: 8) {
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
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.textBackgroundColor))
                    )
                } else if let readmeContent = readmeContent {
                    VStack(alignment: .leading, spacing: 8) {
                        ScrollView {
                            Text(readmeContent)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                        }
                        .frame(maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.textBackgroundColor))
                        )

                        if isReadmeTruncated {
                            Text("Preview only (large file).")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("No README found")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.textBackgroundColor))
                    )
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            // Actions (compact)
            VStack(alignment: .leading, spacing: 6) {
                Text("Actions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button(action: {
                        Task { await viewModel.toggleEnableDisable(skill) }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: skill.isEnabled ? "eye.slash" : "eye")
                                .font(.system(size: 12, weight: .medium))
                            Text(skill.isEnabled ? "Disable" : "Enable")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)

                    Group {
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
                                HStack(spacing: 6) {
                                    Image(systemName: "tray.and.arrow.down")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Move")
                                        .font(.system(size: 12, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 9))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                                .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        } else if case .workspace = skill.location {
                            Button(action: {
                                Task { await viewModel.moveSkillToGlobal(skill) }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Move")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.controlBackgroundColor))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                                )
                                .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }

                    Button(role: .destructive, action: {
                        showDeleteConfirm = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12, weight: .medium))
                            Text("Delete")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
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
        .onChange(of: skill.path.path) { _ in
            loadReadme()
        }
        .onDisappear {
            readmeLoadTask?.cancel()
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
        readmeLoadTask?.cancel()

        // Reset state immediately when skill changes
        readmeContent = nil
        isReadmeTruncated = false
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

        let now = Date()
        let shouldDebounce = now.timeIntervalSince(lastReadmeLoadDate) < readmeDebounceInterval
        lastReadmeLoadDate = now

        readmeLoadTask = Task(priority: .userInitiated) {
            if shouldDebounce {
                try? await Task.sleep(nanoseconds: UInt64(readmeDebounceInterval * 1_000_000_000))
                if Task.isCancelled {
                    return
                }
            }

            for candidate in candidates {
                if Task.isCancelled {
                    return
                }
                if FileManager.default.fileExists(atPath: candidate.path) {
                    if let preview = FastTextFileReader.readPreview(at: candidate, maxBytes: 64 * 1024) {
                        if Task.isCancelled {
                            return
                        }
                        await MainActor.run {
                            self.readmeContent = preview.content
                            self.isReadmeTruncated = preview.isTruncated
                            self.isLoadingReadme = false
                        }
                        return
                    }
                }
            }

            if Task.isCancelled {
                return
            }
            await MainActor.run {
                self.readmeContent = nil
                self.isReadmeTruncated = false
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
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            if mono {
                Text(value)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            } else {
                Text(value)
                    .font(.system(size: 13))
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
