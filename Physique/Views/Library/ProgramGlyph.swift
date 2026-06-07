import SwiftUI

struct ProgramGlyph: View {
    let text: String
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: text)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(Color.onAccent)
            .frame(width: size, height: size)
            .background(Color.accent)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}
