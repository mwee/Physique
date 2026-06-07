import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyweightEntry.date, order: .reverse) private var bodyweightEntries: [BodyweightEntry]
    @Query(sort: \OneRepMaxEntry.date, order: .reverse) private var oneRepMaxes: [OneRepMaxEntry]

    @State private var showBodyweightSheet = false
    @State private var showPaywall = false

    // 1RM row entry
    @State private var showLiftPicker = false
    @State private var showLiftWeightEntry = false
    @State private var newLiftWeight = ""
    @State private var pendingLift: TrackedLift?
    @State private var pickedExercise: Exercise?

    struct TrackedLift: Identifiable, Equatable {
        let id: String
        let name: String
    }

    // Default lifts always shown so the user has somewhere to start.
    private static let defaultLifts: [TrackedLift] = [
        TrackedLift(id: "deadlift", name: "Deadlift"),
        TrackedLift(id: "bench", name: "Bench Press"),
        TrackedLift(id: "squat", name: "Back Squat"),
        TrackedLift(id: "ohp", name: "Overhead Press"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                populatedContent
            }
            .background(theme.bg)
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showBodyweightSheet) {
            BodyweightSheet()
                .environment(\.theme, PhysiqueColors.dark)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
                .environment(\.theme, PhysiqueColors.dark)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showLiftPicker, onDismiss: {
            if let picked = pickedExercise {
                pendingLift = TrackedLift(id: picked.id, name: picked.name)
                pickedExercise = nil
                newLiftWeight = ""
                showLiftWeightEntry = true
            }
        }) {
            ExercisePickerSheet { exercise in
                pickedExercise = exercise
            }
            .environment(\.theme, PhysiqueColors.dark)
            .preferredColorScheme(.dark)
        }
        .alert("Set 1RM", isPresented: $showLiftWeightEntry) {
            TextField("Weight", text: $newLiftWeight)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) {
                newLiftWeight = ""
                pendingLift = nil
            }
            Button("Save") {
                saveLiftEntry()
            }
        } message: {
            Text("Enter your 1 rep max for \(pendingLift?.name ?? "this exercise") in lb.")
        }
    }

    // MARK: - Populated Content

    private var populatedContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenHeader(title: "Progress")

            // Bodyweight card
            bodyweightCard
                .padding(.horizontal, Spacing.s4)

            // 1RM section
            SectionLabel(text: "1 Rep Max")
                .padding(.top, Spacing.s6)
                .padding(.bottom, Spacing.s3)

            oneRepMaxList
                .padding(.horizontal, Spacing.s4)

            // Workout-derived sections (only once a workout exists)
            if !sessions.isEmpty {
                // PR nudge card
                prNudgeCard
                    .padding(.horizontal, Spacing.s4)
                    .padding(.top, Spacing.s6)

                // Weekly volume
                SectionLabel(text: "Weekly Volume")
                    .padding(.top, Spacing.s6)
                    .padding(.bottom, Spacing.s3)

                weeklyVolumeCard
                    .padding(.horizontal, Spacing.s4)
            }

            // Pro-locked section
            proLockedSection
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s6)

            Spacer()
                .frame(height: Spacing.s10)
        }
    }

    // MARK: - Bodyweight Card

    private var bodyweightCard: some View {
        Button {
            showBodyweightSheet = true
        } label: {
            HStack(spacing: Spacing.s3) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.xs)
                        .fill(Color.accent.opacity(0.22))
                        .frame(width: 34, height: 34)
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bodyweight")
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(theme.text)
                    if let latest = bodyweightEntries.first {
                        Text("\(WeightFormatter.format(latest.weight)) \(latest.unit.displayName)")
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text2)
                    } else {
                        Text("No entries")
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text3)
                    }
                }

                Spacer()

                Button {
                    showBodyweightSheet = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.accent.opacity(0.22))
                            .frame(width: 32, height: 32)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.accent)
                    }
                }
            }
            .card()
        }
        .buttonStyle(.plain)
    }

    // MARK: - 1RM List

    /// Default lifts first, then any other lifts the user has logged.
    private var trackedLifts: [TrackedLift] {
        var seen = Set<String>()
        var result: [TrackedLift] = []
        for lift in Self.defaultLifts {
            result.append(lift)
            seen.insert(lift.id)
        }
        for entry in oneRepMaxes where !seen.contains(entry.exerciseId) {
            result.append(TrackedLift(id: entry.exerciseId, name: entry.exerciseName))
            seen.insert(entry.exerciseId)
        }
        return result
    }

    private func latestOneRM(for liftId: String) -> OneRepMaxEntry? {
        oneRepMaxes.first { $0.exerciseId == liftId }
    }

    private var oneRepMaxList: some View {
        VStack(spacing: 0) {
            ForEach(trackedLifts) { lift in
                Button {
                    pendingLift = lift
                    newLiftWeight = latestOneRM(for: lift.id).map { WeightFormatter.format($0.weight) } ?? ""
                    showLiftWeightEntry = true
                } label: {
                    HStack(spacing: Spacing.s3) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Radius.xs)
                                .fill(Color.accent.opacity(0.22))
                                .frame(width: 34, height: 34)
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Color.accent)
                        }

                        Text(lift.name)
                            .font(.system(size: TypeScale.body, weight: .semibold))
                            .foregroundStyle(theme.text)

                        Spacer()

                        if let latest = latestOneRM(for: lift.id) {
                            Text("\(WeightFormatter.format(latest.weight)) \(latest.unit.displayName)")
                                .font(.system(size: TypeScale.body, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(theme.text)
                        } else {
                            Text("Add")
                                .font(.system(size: TypeScale.sub, weight: .semibold))
                                .foregroundStyle(Color.accent)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.text3)
                    }
                    .padding(.horizontal, Spacing.s4)
                    .padding(.vertical, Spacing.s3)
                }
                .buttonStyle(.plain)

                Divider()
                    .background(theme.hairline)
                    .padding(.leading, Spacing.s4)
            }

            // Add lift row
            Button {
                showLiftPicker = true
            } label: {
                HStack(spacing: Spacing.s3) {
                    ZStack {
                        Circle()
                            .fill(Color.accent.opacity(0.22))
                            .frame(width: 34, height: 34)
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.accent)
                    }

                    Text("Add lift to track")
                        .font(.system(size: TypeScale.body, weight: .semibold))
                        .foregroundStyle(Color.accent)

                    Spacer()
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s3)
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

    private func saveLiftEntry() {
        guard let lift = pendingLift,
              let weight = Double(newLiftWeight), weight > 0 else {
            newLiftWeight = ""
            pendingLift = nil
            return
        }
        let entry = OneRepMaxEntry(
            exerciseId: lift.id,
            exerciseName: lift.name,
            weight: weight,
            unit: .lb,
            date: Date()
        )
        modelContext.insert(entry)
        newLiftWeight = ""
        pendingLift = nil
    }

    // MARK: - PR Nudge Card

    private var prNudgeCard: some View {
        HStack(spacing: Spacing.s3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 18))
                .foregroundStyle(Color.prGold)

            VStack(alignment: .leading, spacing: 2) {
                Text("You\u{2019}re due for a PR")
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Text("Your top lifts are trending up. Push for a new record this week.")
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
            }

            Spacer()
        }
        .padding(Spacing.s4)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.prGold.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Weekly Volume Card

    private var weeklyVolumeCard: some View {
        let volumeHistory = ProgressEngine.weeklyVolumeHistory(sessions: sessions, weeks: 8)
        let currentVolume = volumeHistory.last ?? 0

        return VStack(alignment: .leading, spacing: Spacing.s4) {
            HStack(alignment: .lastTextBaseline) {
                Text("Volume")
                    .font(.system(size: TypeScale.body, weight: .semibold))
                    .foregroundStyle(theme.text)
                Spacer()
                Text(WeightFormatter.formatVolume(currentVolume))
                    .font(.system(size: TypeScale.title2, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.text)
                Text("lb")
                    .font(.system(size: TypeScale.sub, weight: .medium))
                    .foregroundStyle(theme.text3)
            }

            BarChartView(data: volumeHistory, height: 96)

            HStack {
                Text("8 weeks ago")
                    .font(.system(size: TypeScale.caption))
                    .foregroundStyle(theme.text3)
                Spacer()
                Text("This week")
                    .font(.system(size: TypeScale.caption))
                    .foregroundStyle(theme.text3)
            }
        }
        .card()
    }

    // MARK: - Pro Locked Section

    private var proLockedSection: some View {
        VStack(spacing: Spacing.s4) {
            SectionLabel(text: "Advanced Insights")

            Button {
                showPaywall = true
            } label: {
                VStack(spacing: Spacing.s4) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.md)
                            .fill(theme.surface2)
                            .frame(width: 52, height: 52)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(theme.text3)
                    }

                    VStack(spacing: Spacing.s2) {
                        Text("Plateau Detection")
                            .font(.system(size: TypeScale.callout, weight: .bold))
                            .foregroundStyle(theme.text)
                        Text("Unlock Physique Pro to see when your lifts stall and get suggestions to break through.")
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text2)
                            .multilineTextAlignment(.center)
                    }

                    PillView(text: "PRO", tone: .accent, icon: "bolt.fill")
                }
                .frame(maxWidth: .infinity)
                .card()
            }
            .buttonStyle(.plain)
        }
    }
}
