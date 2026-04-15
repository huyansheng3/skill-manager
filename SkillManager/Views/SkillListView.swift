import SwiftUI

struct SkillListView: View {
    @EnvironmentObject var viewModel: SkillListViewModel

    var body: some View {
        List {
            ForEach(viewModel.allSkills) { skill in
                SkillRowView(
                    skill: skill,
                    isSelected: viewModel.selectedSkill?.id == skill.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedSkill = skill
                }
            }
        }
        .listStyle(.plain)
    }
}

struct SkillListView_Previews: PreviewProvider {
    static var previews: some View {
        SkillListView()
            .environmentObject(SkillListViewModel())
    }
}