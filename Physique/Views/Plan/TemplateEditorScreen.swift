import SwiftUI
import SwiftData

/// Create or edit a single-workout template, laid out like the active
/// workout: each exercise is a block of individually editable set rows
/// (SET · LB · REPS), typed directly on the keyboard.
struct TemplateEditorScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppCoordinator.self) var coordinator

    /// When set, the screen edits this template in place.
    var existing: WorkoutTemplate? = nil

    @State private var name: String = ""
    @State private var items: [DraftItem] = []
    @State private var showPicker = false
    @State private var loaded = false
    /// What was loaded, so Save only lights up once something changed.
    @State private var savedName: String = ""
    @State private var savedItems: [DraftItem] = []

    struct DraftSet: Identifiable, Equatable {
        let id = UUID()
        var weight: Double
        var reps: Int

        static func == (lhs: DraftSet, rhs: DraftSet) -> Bool {
            lhs.weight == rhs.weight && lhs.reps == rhs.reps
        }
    }

    struct DraftItem: Identifiable, Equatable {
        let id = UUID()
        var exerciseId: String?
        var name: String
        var sets: [DraftSet] = [DraftSet(weight: 0, reps: 5)]

        static func == (lhs: DraftItem, rhs: DraftItem) -> Bool {
            lhs.exerciseId == rhs.exerciseId && lhs.name == rhs.name && lhs.sets == rhs.sets
        }
    }

    private var isEditing: Bool { existing != nil }

    private var isDirty: Bool {
        name.trimmingCharacters(in: .whitespaces) != savedName || items != savedItems
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !items.isEmpty
            && items.allSatisfy { !$0.sets.isEmpty }
            && (!isEditing || isDirty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Kind explainer
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(theme.text2)
                    Text("A template is one reusable workout with fixed targets. It never changes your program or training maxes.")
                        .font(.system(size: TypeScale.footnote))
                        .foregroundStyle(theme.text3)
                }
                .padding(.horizontal, Spacing.s5)
                .padding(.top, Spacing.s4)

                // Name
                SectionLabel(text: "Template name")
                    .padding(.top, Spacing.s5)
                    .padding(.bottom, Spacing.s2)
                TextField("e.g. Push Day", text: $name)
                    .font(.system(size: TypeScale.body))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                    .padding(.horizontal, Spacing.s4)

                // Exercise blocks
                if items.isEmpty {
                    Text("Add exercises, then dial in each set\u{2019}s weight and reps.")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text3)
                        .padding(.horizontal, Spacing.s5)
                        .padding(.top, Spacing.s6)
                } else {
                    VStack(spacing: Spacing.s3) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { itemIndex, _ in
                            exerciseBlock(itemIndex)
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s5)
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

                if isEditing {
                    Button {
                        startWorkout()
                    } label: {
                        HStack(spacing: Spacing.s2) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start this workout")
                        }
                    }
                    .buttonStyle(.physique(.ghost))
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s3)
                }
            }
            .padding(.bottom, Spacing.s10)
        }
        .background(theme.bg)
        .navigationTitle(isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isEditing ? "Save changes" : "Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .sheet(isPresented: $showPicker) {
            ExercisePickerSheet { exercise in
                items.append(DraftItem(
                    exerciseId: exercise.id,
                    name: exercise.name,
                    sets: [DraftSet(weight: 0, reps: 5), DraftSet(weight: 0, reps: 5), DraftSet(weight: 0, reps: 5)]
                ))
            }
            .environment(\.theme, PhysiqueColors.dark)
            .preferredColorScheme(.dark)
        }
        .onAppear(perform: loadExisting)
    }

    // MARK: - Exercise block (workout-view style)

    private func exerciseBlock(_ itemIndex: Int) -> some View {
        let item = items[itemIndex]

        return VStack(spacing: 0) {
            // Header
            HStack {
                Text(item.name)
                    .font(.system(size: TypeScale.callout, weight: .bold))
                    .foregroundStyle(Color.accent)
                Spacer()
                Button {
                    items.remove(at: itemIndex)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.dangerRed)
                }
                .accessibilityLabel("Remove \(item.name)")
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)
            .padding(.bottom, Spacing.s2)

            // Column headers
            HStack(spacing: 7) {
                Text("Set")
                    .frame(width: 30, alignment: .leading)
                Spacer()
                Text("lb")
                    .frame(width: 72, alignment: .center)
                Text("Reps")
                    .frame(width: 60, alignment: .center)
                Spacer().frame(width: 30)
            }
            .font(.system(size: TypeScale.caption, weight: .semibold))
            .foregroundStyle(theme.text3)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, Spacing.s4)
            .frame(height: 28)

            // Set rows
            ForEach(Array(item.sets.enumerated()), id: \.element.id) { setIndex, _ in
                HStack(spacing: 7) {
                    Text("\(setIndex + 1)")
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.text)
                        .frame(width: 30, alignment: .leading)

                    Spacer()

                    WeightField(value: setBinding(itemIndex, setIndex, \.weight))
                        .accessibilityIdentifier("tplWeight-\(itemIndex)-\(setIndex)")

                    RepsField(value: setBinding(itemIndex, setIndex, \.reps))
                        .accessibilityIdentifier("tplReps-\(itemIndex)-\(setIndex)")

                    Button {
                        guard items[itemIndex].sets.count > 1 else { return }
                        items[itemIndex].sets.remove(at: setIndex)
                    } label: {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(item.sets.count > 1 ? theme.text3 : theme.surface3)
                    }
                    .disabled(item.sets.count <= 1)
                    .frame(width: 30)
                    .accessibilityLabel("Remove set \(setIndex + 1)")
                }
                .padding(.horizontal, Spacing.s4)
                .frame(height: 48)
            }

            // Add set
            Button {
                let last = items[itemIndex].sets.last
                items[itemIndex].sets.append(DraftSet(weight: last?.weight ?? 0, reps: last?.reps ?? 5))
            } label: {
                Text("+ Add set")
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(theme.text2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.s3)
                    .background(theme.surface2.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    private func setBinding<T>(_ itemIndex: Int, _ setIndex: Int, _ keyPath: WritableKeyPath<DraftSet, T>) -> Binding<T> {
        Binding(
            get: {
                guard items.indices.contains(itemIndex), items[itemIndex].sets.indices.contains(setIndex) else {
                    return DraftSet(weight: 0, reps: 5)[keyPath: keyPath]
                }
                return items[itemIndex].sets[setIndex][keyPath: keyPath]
            },
            set: { newValue in
                guard items.indices.contains(itemIndex), items[itemIndex].sets.indices.contains(setIndex) else { return }
                items[itemIndex].sets[setIndex][keyPath: keyPath] = newValue
            }
        )
    }

    // MARK: - Load / Save

    /// Loads either kind of template as editable set rows. Program-day
    /// templates expand through the session builder so their computed weights
    /// become concrete, editable targets.
    private func loadExisting() {
        guard !loaded, let existing else { return }
        loaded = true
        name = existing.name
        switch existing.kind {
        case .custom:
            items = existing.sortedItems.map { item in
                DraftItem(
                    exerciseId: item.exerciseId,
                    name: item.name,
                    sets: item.setSpecs.map { DraftSet(weight: $0.weight, reps: $0.reps) }
                )
            }
        case .program:
            items = TemplateService.exercises(from: existing).map { exercise in
                let working = exercise.sets.filter { !$0.type.isWarmup }
                return DraftItem(
                    exerciseId: exercise.exId,
                    name: exercise.name,
                    sets: working.isEmpty
                        ? [DraftSet(weight: 0, reps: 5)]
                        : working.map { DraftSet(weight: $0.weight, reps: $0.reps) }
                )
            }
        }
        savedName = name
        savedItems = items
    }

    private func startWorkout() {
        guard let existing else { return }
        let exercises = TemplateService.exercises(from: existing)
        guard !exercises.isEmpty else {
            coordinator.showToast("Add an exercise first", icon: "exclamationmark.triangle")
            return
        }
        coordinator.launchWorkout(name: existing.name, exercises: exercises)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let template: WorkoutTemplate
        if let existing {
            template = existing
            template.name = trimmed
            // Once edited, a program-day template is just a list of exercises.
            template.kind = .custom
            template.programId = nil
            for old in existing.items {
                modelContext.delete(old)
            }
        } else {
            template = WorkoutTemplate(name: trimmed, kindRaw: TemplateKind.custom.rawValue)
            modelContext.insert(template)
        }

        for (index, draft) in items.enumerated() {
            let item = TemplateItem(
                orderIndex: index,
                name: draft.name,
                exerciseId: draft.exerciseId,
                targetSets: draft.sets.count,
                targetReps: draft.sets.first?.reps ?? 5,
                targetWeight: draft.sets.map(\.weight).max() ?? 0
            )
            item.setSpecs = draft.sets.map { TemplateSetSpec(weight: $0.weight, reps: $0.reps) }
            item.template = template
            modelContext.insert(item)
        }
        try? modelContext.save()
        savedName = trimmed
        savedItems = items
        coordinator.showToast(isEditing ? "Template updated" : "Template saved", icon: "checkmark", tone: .success)
        dismiss()
    }
}
