import SwiftUI
import SwiftData

struct LibraryBrowseScreen: View {
    @Environment(\.theme) var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]
    @State private var searchQuery = ""
    @State private var selectedCategory = "All"

    private var categories: [String] {
        ["All"] + BuiltInPrograms.categories + ["Mine"]
    }

    /// Custom programs first (when shown), then built-ins — like the design's
    /// All/Mine template list.
    private var filteredPrograms: [ProgramDefinition] {
        var programs: [ProgramDefinition]
        switch selectedCategory {
        case "Mine":
            programs = customPrograms.map { $0.definition(forWeek: 0) }
        case "All":
            programs = customPrograms.map { $0.definition(forWeek: 0) } + BuiltInPrograms.programs
        default:
            programs = BuiltInPrograms.programs.filter { $0.tags.contains(selectedCategory) }
        }
        if !searchQuery.isEmpty {
            programs = programs.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.author.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return programs
    }

    private func customProgram(for definition: ProgramDefinition) -> CustomProgram? {
        customPrograms.first { $0.programId == definition.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // What a program is
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.accent)
                    Text("Multi-week plans. Every session is generated from your maxes, which stay locked for the block.")
                        .font(.system(size: TypeScale.footnote))
                        .foregroundStyle(theme.text3)
                }
                .padding(.horizontal, Spacing.s5)
                .padding(.top, Spacing.s3)

                // Search
                HStack(spacing: Spacing.s2) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundStyle(theme.text3)
                    TextField("Search programs", text: $searchQuery)
                        .font(.system(size: TypeScale.body))
                        .foregroundStyle(theme.text)
                }
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s3)
                .background(theme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s3)

                // Category chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s2) {
                        ForEach(categories, id: \.self) { category in
                            Button(category) {
                                selectedCategory = category
                            }
                            .font(.system(size: TypeScale.sub, weight: .semibold))
                            .foregroundStyle(selectedCategory == category ? .onAccent : theme.text2)
                            .padding(.horizontal, Spacing.s4)
                            .padding(.vertical, Spacing.s2)
                            .background(selectedCategory == category ? Color.accent : theme.surface2)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, Spacing.s4)
                }
                .padding(.top, Spacing.s4)

                // Program list
                VStack(spacing: Spacing.s3) {
                    if filteredPrograms.isEmpty {
                        Text("Nothing here yet \u{2014} build a program below.")
                            .font(.system(size: TypeScale.sub))
                            .foregroundStyle(theme.text3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s6)
                    }
                    ForEach(filteredPrograms) { program in
                        NavigationLink(destination: ProgramDetailScreen(program: program)) {
                            ProgramCardView(program: program)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if let custom = customProgram(for: program) {
                                Button(role: .destructive) {
                                    modelContext.delete(custom)
                                    try? modelContext.save()
                                } label: {
                                    Label("Delete program", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)

                // Build a program
                NavigationLink(destination: ProgramBuilderScreen()) {
                    HStack(spacing: Spacing.s2) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Build a program")
                    }
                }
                .buttonStyle(.physique(.secondary))
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)
                .padding(.bottom, Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle("Programs")
    }
}

// MARK: - Program Card

struct ProgramCardView: View {
    @Environment(\.theme) var theme
    let program: ProgramDefinition

    var body: some View {
        HStack(spacing: Spacing.s4) {
            ProgramGlyph(text: program.glyph)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Spacing.s2) {
                    Text(program.name)
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .foregroundStyle(theme.text)
                    if program.id.hasPrefix("custom-") {
                        PillView(text: "Mine", tone: .accent)
                    }
                }
                Text(program.author)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text2)
                HStack(spacing: Spacing.s2) {
                    Text(program.days)
                    Text("\u{00B7}")
                    Text(program.cycle)
                }
                .font(.system(size: TypeScale.footnote, weight: .semibold))
                .foregroundStyle(theme.text3)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.text3)
        }
        .card()
    }
}
