import SwiftUI

/// Horizontal "All / Barbell / Dumbbell / …" chips used by the exercise
/// library and the exercise picker.
struct EquipmentFilterChips: View {
    @Environment(\.theme) var theme
    @Binding var selection: ExerciseType?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s2) {
                chip(title: "All", icon: nil, isSelected: selection == nil) { selection = nil }
                ForEach(ExerciseType.allCases) { type in
                    chip(title: type.displayName, icon: type.icon, isSelected: selection == type) {
                        selection = selection == type ? nil : type
                    }
                }
            }
            .padding(.horizontal, Spacing.s4)
        }
    }

    private func chip(title: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: TypeScale.sub, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .onAccent : theme.text2)
            .padding(.horizontal, Spacing.s3)
            .padding(.vertical, Spacing.s2)
            .background(isSelected ? Color.accent : theme.surface2)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
