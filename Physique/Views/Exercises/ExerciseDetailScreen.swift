import SwiftUI
import SwiftData

struct ExerciseDetailScreen: View {
    @Environment(\.theme) var theme
    let exercise: Exercise
    @State private var chartRange = "8W"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Pills
                HStack(spacing: Spacing.s2) {
                    PillView(text: exercise.muscleGroup.rawValue, tone: .neutral)
                    PillView(text: exercise.equipmentType.displayName, tone: .neutral)
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s3)

                // Chart card
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Estimated 1RM")
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text2)
                        Spacer()
                        if let delta = exercise.e1rmDelta, delta > 0 {
                            Text("\u{25B2} \(WeightFormatter.format(delta)) lb")
                                .font(.system(size: TypeScale.sub, weight: .bold))
                                .foregroundStyle(Color.successGreen)
                        }
                    }

                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        if let e1rm = exercise.bestEstimated1RM {
                            Text(WeightFormatter.format(e1rm))
                                .font(.system(size: 40, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.text)
                        } else {
                            Text("\u{2014}")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(theme.text3)
                        }
                        Text("lb")
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                    .padding(.top, Spacing.s1)

                    if !exercise.e1rmHistory.isEmpty {
                        LineChartView(data: exercise.e1rmHistory, height: 130)
                            .padding(.top, Spacing.s3)
                    }

                    // Range selector
                    HStack(spacing: Spacing.s2) {
                        ForEach(["8W", "6M", "1Y", "All"], id: \.self) { range in
                            Button(range) {
                                chartRange = range
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(chartRange == range ? theme.text : theme.text2)
                            .padding(.horizontal, Spacing.s3)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity)
                            .background(chartRange == range ? theme.surface : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.full))
                        }
                    }
                    .padding(4)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.full))
                    .padding(.top, Spacing.s4)
                }
                .card()
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)

                // Personal records
                SectionLabel(text: "Personal records")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                VStack(spacing: 0) {
                    ForEach(exercise.records.sorted(by: { $0.recordType < $1.recordType })) { record in
                        HStack {
                            Text(recordLabel(record.recordType))
                                .font(.system(size: TypeScale.sub))
                                .foregroundStyle(theme.text2)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.prGold)
                                Text(record.detail)
                                    .font(.system(size: TypeScale.body, weight: .bold))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.text)
                            }
                        }
                        .padding(.horizontal, Spacing.s4)
                        .padding(.vertical, Spacing.s4)
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
            .padding(.bottom, Spacing.s10)
        }
        .background(theme.bg)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func recordLabel(_ type: String) -> String {
        switch type {
        case "weight": "Heaviest weight"
        case "e1rm": "Best estimated 1RM"
        case "volume": "Best session volume"
        default: type.capitalized
        }
    }
}
