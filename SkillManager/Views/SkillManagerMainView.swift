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

                    List {
                        WorkspaceSidebarView(selectedWorkspace: $selectedWorkspace)
                    }
                    .listStyle(.sidebar)
                }
                .frame(minWidth: 280, maxWidth: 320)

                Divider()

                // Detail pane
                if let selectedSkill = viewModel.selectedSkill {
                    SkillDetailView(skill: selectedSkill)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Select a skill to view details")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.textBackgroundColor).opacity(0.5))
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
                }
            }
        }
        .onAppear {
            Task { await viewModel.load() }
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { viewModel.errorMessage = $0?.error }
        )) { wrapper in
            Alert(
                title: Text("Error"),
                message: Text(wrapper.error),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}