import SwiftUI

struct SkillRowView: View {
    let skill: Skill
    let isSelected: Bool

    private var titleColor: Color {
        if isSelected {
            return .accentColor
        }
        return skill.isEnabled ? .primary : .secondary
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(skill.displayName)
                    .font(.callout)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(titleColor)

                if let description = skill.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .accentColor.opacity(0.85) : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if !skill.isEnabled {
                Text("Disabled")
                    .font(.caption)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
        )
    }
}
