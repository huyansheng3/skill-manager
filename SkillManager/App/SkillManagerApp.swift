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
