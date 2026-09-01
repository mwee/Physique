import SwiftUI

/// The Physique barbell mark from the design system, drawn from the
/// prototype's 1024×540 SVG: a gently bowed bar with blue inner plates
/// and gold outer plates. Pass `mono` to render it in a single color.
struct BrandMark: View {
    var height: CGFloat = 24
    var mono: Color? = nil

    var body: some View {
        Canvas { context, size in
            let s = size.height / 540

            var bar = Path()
            bar.move(to: CGPoint(x: 120 * s, y: 232 * s))
            bar.addQuadCurve(
                to: CGPoint(x: 904 * s, y: 232 * s),
                control: CGPoint(x: 512 * s, y: 362 * s)
            )
            context.stroke(
                bar,
                with: .color(mono ?? Color(hex: 0xC3CAD6)),
                style: StrokeStyle(lineWidth: 66 * s, lineCap: .round)
            )

            let plates: [(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, color: Color)] = [
                (186, 44, 118, 452, mono ?? .accent),
                (720, 44, 118, 452, mono ?? .accent),
                (64, 96, 118, 348, mono ?? .prGold),
                (842, 96, 118, 348, mono ?? .prGold),
            ]
            for plate in plates {
                let rect = CGRect(x: plate.x * s, y: plate.y * s, width: plate.w * s, height: plate.h * s)
                context.fill(Path(roundedRect: rect, cornerRadius: 42 * s), with: .color(plate.color))
            }
        }
        .frame(width: height * 1024 / 540, height: height)
        .accessibilityHidden(true)
    }
}

/// The 2pt brand gradient rule that sits under the Home header.
struct BrandRule: View {
    var body: some View {
        LinearGradient(
            colors: [Color(hex: 0x3B7BF6), Color(hex: 0x5C92FF), Color.prGold],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 2)
        .clipShape(Capsule())
        .opacity(0.85)
        .accessibilityHidden(true)
    }
}

/// Round accent bubble with the user's initials (or a person glyph when
/// no name is set). Used top-right on Home and in Settings.
struct AvatarBubble: View {
    let name: String
    var size: CGFloat = 40

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)
        return String(parts).uppercased()
    }

    var body: some View {
        ZStack {
            Circle().fill(Color.accent)
            if initials.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(Color.onAccent)
            } else {
                Text(initials)
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundStyle(Color.onAccent)
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Profile")
    }
}
