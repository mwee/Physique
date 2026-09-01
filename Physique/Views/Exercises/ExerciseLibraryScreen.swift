import SwiftUI
import SwiftData

struct ExerciseLibraryScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var viewModel = ExerciseLibraryViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ScreenHeader(title: "Exercises")

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
                                    NavigationLink(destination: ExerciseDetailScreen(exercise: exercise)) {
                                        ExerciseRow(exercise: exercise)
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
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                SeedDataService.seedIfNeeded(context: modelContext)
            }
        }
    }
}

private struct ExerciseRow: View {
    @Environment(\.theme) var theme
    let exercise: Exercise

    var body: some View {
        HStack(spacing: Spacing.s3) {
            // Icon
            ZStack {
                if let thumbnail = ExerciseMediaService.frames(for: exercise.id).first {
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(Color.white)
                        .frame(width: 38, height: 38)
                    Image(thumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                } else {
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(theme.surface2)
                        .frame(width: 38, height: 38)
                    Image(systemName: exercise.equipmentType.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(theme.text2)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                HStack(spacing: 4) {
                    Text(exercise.equipmentType.displayName)
                        .foregroundStyle(theme.text3)
                    if let e1rm = exercise.bestEstimated1RM {
                        Text("·")
                            .foregroundStyle(theme.text3)
                        Text("e1RM \(WeightFormatter.format(e1rm)) lb")
                            .foregroundStyle(theme.text3)
                    }
                }
                .font(.system(size: TypeScale.footnote))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.text3)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
    }
}
