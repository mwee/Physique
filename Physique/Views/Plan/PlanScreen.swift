import SwiftUI
import SwiftData

struct PlanScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppCoordinator.self) var coordinator
    @Query private var activePrograms: [ActiveProgram]
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse) private var templates: [WorkoutTemplate]
    @Query private var profiles: [UserProfile]

    @State private var selectedMode: PlanMode?

    enum PlanMode: String, CaseIterable {
        case templates = "Templates"
        case coach = "AI Coach"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(title: "Plan")

                // Mode toggle
                modeToggle
                    .padding(.horizontal, Spacing.s4)

                // Body
                ScrollView {
                    switch resolvedMode {
                    case .templates:
                        templatesBody
                    case .coach:
                        CoachBody()
                    }
                }
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if selectedMode == nil {
                    selectedMode = profiles.first?.trainingMode == "coach" ? .coach : .templates
                }
            }
        }
    }

    private var resolvedMode: PlanMode {
        selectedMode ?? (profiles.first?.trainingMode == "coach" ? .coach : .templates)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(PlanMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: TypeScale.sub, weight: .semibold))
                        .foregroundStyle(resolvedMode == mode ? theme.text : theme.text3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.s3)
                        .background(
                            resolvedMode == mode
                                ? theme.surface2
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.s1)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Templates Body

    private var templatesBody: some View {
        VStack(spacing: 0) {
            if let program = activePrograms.first {
                // Active program card
                activeProgramCard(program)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s4)
            } else {
                // Empty state
                emptyTemplatesState
            }

            // Browse library button
            NavigationLink(destination: LibraryBrowseScreen()) {
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 14))
                    Text("Browse library")
                }
            }
            .buttonStyle(.physique(.secondary))
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s4)

            // My Templates
            myTemplatesSection

            Spacer()
                .frame(height: Spacing.s10)
        }
    }

    // MARK: - My Templates

    private var myTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionLabel(text: "My Templates")
                Spacer()
                NavigationLink(destination: TemplateEditorScreen()) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("New")
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                    }
                    .foregroundStyle(Color.accent)
                }
            }
            .padding(.horizontal, Spacing.s4)
            .padding(.top, Spacing.s6)
            .padding(.bottom, Spacing.s3)

            if templates.isEmpty {
                Text("Save a program from the library or create your own to see it here.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text3)
                    .padding(.horizontal, Spacing.s4)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(templates.enumerated()), id: \.element.id) { index, template in
                        templateRow(template)
                        if index < templates.count - 1 {
                            Divider()
                                .background(theme.hairline)
                                .padding(.leading, Spacing.s4)
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

    private func templateRow(_ template: WorkoutTemplate) -> some View {
        HStack(spacing: Spacing.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.xs)
                    .fill(theme.surface2)
                    .frame(width: 38, height: 38)
                Image(systemName: template.kind == .program ? "doc.text.fill" : "square.and.pencil")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.text2)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text(template.kind == .program ? "Program" : "\(template.items.count) exercises")
                    .font(.system(size: TypeScale.footnote))
                    .foregroundStyle(theme.text3)
            }

            Spacer()

            Button {
                startTemplate(template)
            } label: {
                Text("Start")
                    .font(.system(size: TypeScale.sub, weight: .semibold))
                    .foregroundStyle(Color.onAccent)
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s2)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.s4)
        .padding(.vertical, Spacing.s3)
        .contextMenu {
            Button(role: .destructive) {
                deleteTemplate(template)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func startTemplate(_ template: WorkoutTemplate) {
        let exercises = TemplateService.exercises(from: template)
        guard !exercises.isEmpty else {
            coordinator.showToast("This template has no exercises", icon: "exclamationmark.triangle")
            return
        }
        coordinator.launchWorkout(name: template.name, exercises: exercises)
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        modelContext.delete(template)
        try? modelContext.save()
    }

    private var emptyTemplatesState: some View {
        VStack(spacing: Spacing.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.md)
                    .fill(theme.surface2)
                    .frame(width: 52, height: 52)
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.text3)
            }

            VStack(spacing: Spacing.s2) {
                Text("No active program")
                    .font(.system(size: TypeScale.callout, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text("Pick a proven template from the library and Physique will generate your daily sessions automatically.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .card()
        .padding(.horizontal, Spacing.s4)
        .padding(.top, Spacing.s4)
    }

    private func activeProgramCard(_ program: ActiveProgram) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s3) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(program.programId.uppercased())
                        .font(.system(size: TypeScale.callout, weight: .bold))
                        .foregroundStyle(theme.text)
                    Text("Week \(program.currentWeek + 1)")
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                }

                Spacer()

                PillView(text: "Active", tone: .success, icon: "checkmark")
            }

            HStack(spacing: Spacing.s6) {
                programStat("Unit", program.unit.displayName)
                programStat("TM %", "\(program.trainingMaxPercent)%")
            }
        }
        .card()
    }

    private func programStat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: TypeScale.caption, weight: .bold))
                .foregroundStyle(theme.text3)
                .tracking(0.5)
            Text(value)
                .font(.system(size: TypeScale.body, weight: .bold))
                .foregroundStyle(theme.text)
        }
    }

}

