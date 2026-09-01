import SwiftUI
import SwiftData

struct ExercisePickerSheet: View {
    @Environment(\.theme) var theme
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()

    /// Called when the user taps an exercise to add it.
    let onSelect: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.text3)
                        TextField("Search exercises", text: $viewModel.searchQuery)
                            .font(.system(size: TypeScale.body))
                            .foregroundStyle(theme.text)
                    }
                    .padding(.horizontal, Spacing.s3)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)

                    EquipmentFilterChips(selection: $viewModel.equipmentFilter)
                        .padding(.top, Spacing.s3)

                    // Grouped list
                    let groups = viewModel.groupedExercises(exercises)
                    ForEach(groups, id: \.0) { group, items in
                        VStack(alignment: .leading, spacing: 0) {
                            SectionLabel(text: group.rawValue)
                                .padding(.top, Spacing.s5)
                                .padding(.bottom, Spacing.s3)

                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, exercise in
                                    Button {
                                        onSelect(exercise)
                                        dismiss()
                                    } label: {
                                        pickerRow(exercise)
                                    }
                                    .buttonStyle(.plain)

                                    if index < items.count - 1 {
                                        Divider()
                                            .background(theme.hairline)
                                            .padding(.leading, 66)
                                    }
                                }
                            }
                            .background(theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .stroke(theme.hairline, lineWidth: 1)
                            )
                            .padding(.horizontal, Spacing.s4)
                        }
                    }
                }
                .padding(.bottom, Spacing.s10)
            }
            .background(theme.bg)
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.accent)
                }
            }
        }
    }

    private func pickerRow(_ exercise: Exercise) -> some View {
        HStack(spacing: Spacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(theme.surface2)
                    .frame(width: 38, height: 38)
                Image(systemName: exercise.equipmentType.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.text2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text(exercise.equipmentType.displayName)
                    .font(.system(size: TypeScale.footnote))
                    .foregroundStyle(theme.text3)
            }

            Spacer()

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.accent)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
    }
}
