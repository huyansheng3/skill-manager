import SwiftUI

@main
struct SkillManagerApp: App {
    @StateObject private var viewModel = SkillListViewModel()

    var body: some Scene {
        WindowGroup {
            SkillManagerMainView()
                .environmentObject(viewModel)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}

// Placeholder - will be implemented in later tasks
class SkillListViewModel: ObservableObject {
    public init() {}
}

// Placeholder - will be implemented in later tasks
struct SkillManagerMainView: View {
    var body: some View {
        Text("Skill Manager")
    }
}
