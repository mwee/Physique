import SwiftUI

struct ScreenHeader: View {
    @Environment(\.theme) var theme
    let title: String
    var subtitle: String?
    var trailing: (() -> AnyView)?

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: Spacing.s1) {
                Text(title)
                    .font(.system(size: TypeScale.title1, weight: .bold))
                    .foregroundStyle(theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: TypeScale.sub))
                        .foregroundStyle(theme.text2)
                }
            }
            Spacer()
            if let trailing {
                trailing()
            }
        }
        .padding(.horizontal, Spacing.s5)
        .padding(.top, Spacing.s1)
        .padding(.bottom, Spacing.s3)
    }
}
