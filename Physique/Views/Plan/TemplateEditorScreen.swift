import SwiftUI
import SwiftData

struct TemplateEditorScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) var coordinator

    @State private var name: String = ""
    @State private var items: [DraftItem] = []
    @State private var showPicker = false

    struct DraftItem: Identifiable {
        let id = UUID()
        var exerciseId: String?
        var name: String
        var targetSets: Int = 3
        var targetReps: Int = 5
        var targetWeight: Double = 0
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Name
                SectionLabel(text: "Template name")
                    .padding(.top, Spacing.s4)
                    .padding(.bottom, Spacing.s2)
                TextField("e.g. Push Day", text: $name)
                    .font(.system(size: TypeScale.body))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .padding(.horizontal, Spacing.s4)

                // Exercises
                SectionLabel(text: "Exercises")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                if items.isEmpty {
                    Text("Add exercises and set targets for each.")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text3)
                        .padding(.horizontal, Spacing.s4)
                } else {
                    VStack(spacing: Spacing.s3) {
                        ForEach($items) { $item in
                            itemCard($item)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }

                Button {
                    showPicker = true
                } label: {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "plus")
                            .font(.system(size: 14))
                        Text("Add exercise")
                    }
                }
                .buttonStyle(.physique(.secondary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)
            }
            .padding(.bottom, Spacing.s10)
        }
        .background(theme.bg)
        .navigationTitle("New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { exercise in
                items.append(DraftItem(exerciseId: exercise.id, name: exercise.name))
            }
            .environment(\.theme, PhysiqueColors.dark)
            .preferredColorScheme(.dark)
        }
    }

    private func itemCard(_ item: Binding<DraftItem>) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                Text(item.wrappedValue.name)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                Button {
                    items.removeAll { $0.id == item.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dangerRed)
                }
            }

            stepperRow(label: "Sets", value: item.targetSets, range: 1...20, step: 1)
            stepperRow(label: "Reps", value: item.targetReps, range: 1...50, step: 1)
            weightRow(value: item.targetWeight)
        }
        .card()
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
            Spacer()
            Stepper(value: value, in: range, step: step) {
                Text("\(value.wrappedValue)")
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.text)
            }
            .labelsHidden()
            .fixedSize()
            Text("\(value.wrappedValue)")
                .font(.system(size: TypeScale.body, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.text)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private func weightRow(value: Binding<Double>) -> some View {
        HStack {
            Text("Weight")
                .font(.system(size: TypeScale.sub))
                .foregroundStyle(theme.text2)
            Spacer()
            Stepper(value: value, in: 0...2000, step: 5) {
                EmptyView()
            }
            .labelsHidden()
            .fixedSize()
            Text("\(WeightFormatter.format(value.wrappedValue)) lb")
                .font(.system(size: TypeScale.body, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(theme.text)
                .frame(width: 70, alignment: .trailing)
        }
    }

    private func save() {
        let template = WorkoutTemplate(name: name.trimmingCharacters(in: .whitespaces),
                                       kindRaw: TemplateKind.custom.rawValue)
        modelContext.insert(template)
        for (index, draft) in items.enumerated() {
            let item = TemplateItem(
                orderIndex: index,
                name: draft.name,
                exerciseId: draft.exerciseId,
                targetSets: draft.targetSets,
                targetReps: draft.targetReps,
                targetWeight: draft.targetWeight
            )
            item.template = template
            modelContext.insert(item)
        }
        try? modelContext.save()
        coordinator.showToast("Template saved", icon: "checkmark", tone: .success)
        dismiss()
    }
}
