import SwiftUI

struct LibraryBrowseScreen: View {
    @Environment(\.theme) var theme
    @State private var searchQuery = ""
    @State private var selectedCategory = "All"

    private var filteredPrograms: [ProgramDefinition] {
        var programs = BuiltInPrograms.programs
        if selectedCategory != "All" {
            programs = programs.filter { $0.tags.contains(selectedCategory) }
        }
        if !searchQuery.isEmpty {
            programs = programs.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.author.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        return programs
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
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
                        ForEach(BuiltInPrograms.categories, id: \.self) { category in
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
                    ForEach(filteredPrograms) { program in
                        NavigationLink(destination: ProgramDetailScreen(program: program)) {
                            ProgramCardView(program: program)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.s4)
                .padding(.top, Spacing.s4)
                .padding(.bottom, Spacing.s10)
            }
        }
        .background(theme.bg)
        .navigationTitle("Template Library")
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
                Text(program.name)
                    .font(.system(size: TypeScale.body, weight: .bold))
                    .foregroundStyle(theme.text)
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
