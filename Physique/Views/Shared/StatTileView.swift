import SwiftUI

struct StatTileView: View {
    @Environment(\.theme) var theme
    let label: String
    let value: String
    var unit: String?
    var icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s1) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: TypeScale.sub))
                    .foregroundStyle(theme.text3)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: TypeScale.title2, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(theme.text)
                if let unit {
                    Text(unit)
                        .font(.system(size: TypeScale.sub, weight: .medium))
                        .foregroundStyle(theme.text3)
                }
            }
            Text(label)
                .font(.system(size: TypeScale.caption, weight: .medium))
                .foregroundStyle(theme.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: Spacing.s4)
    }
}
