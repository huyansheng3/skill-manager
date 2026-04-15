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

                    WorkspaceSidebarView(selectedWorkspace: $selectedWorkspace)
                        .listStyle(.sidebar)
                }
                .frame(minWidth: 280, maxWidth: 320)

                Divider()

                // Detail pane
                if let selectedSkill = viewModel.selectedSkill {
                    SkillDetailView(skill: selectedSkill)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a skill to view details")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.textBackgroundColor))
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
                    .accessibilityLabel("Refresh skills")
                }
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}