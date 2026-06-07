import SwiftUI

// MARK: - Spacing (4pt grid)
enum Spacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
}

// MARK: - Corner Radii
enum Radius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let full: CGFloat = 999
}

// MARK: - Typography
enum TypeScale {
    static let caption: CGFloat = 11
    static let footnote: CGFloat = 12
    static let sub: CGFloat = 13
    static let body: CGFloat = 15
    static let callout: CGFloat = 17
    static let title3: CGFloat = 20
    static let title2: CGFloat = 24
    static let title1: CGFloat = 30
    static let display: CGFloat = 44
    static let hero: CGFloat = 60
}

// MARK: - Brand / Semantic Colors (theme-independent)
extension Color {
    static let accent = Color(hex: 0x2563EB)
    static let prGold = Color(hex: 0xE0A43B)
    static let prSoft = Color(hex: 0xE0A43B).opacity(0.16)
    static let successGreen = Color(hex: 0x22C55E)
    static let dangerRed = Color(hex: 0xFF453A)
    static let dangerSoft = Color(hex: 0xFF453A).opacity(0.14)
    static let warmup = Color(hex: 0xE0A43B)
    static let onAccent = Color.white
}

// MARK: - Themed Colors
struct PhysiqueColors {
    let bg: Color
    let surface: Color
    let surface2: Color
    let surface3: Color
    let hairline: Color
    let hairlineStrong: Color
    let text: Color
    let text2: Color
    let text3: Color
    let accentSoft: Color
    let accentTint: Color
    let scrim: Color
}

extension PhysiqueColors {
    static let dark = PhysiqueColors(
        bg: Color(hex: 0x08080A),
        surface: Color(hex: 0x151518),
        surface2: Color(hex: 0x1E1E22),
        surface3: Color(hex: 0x29292F),
        hairline: Color.white.opacity(0.08),
        hairlineStrong: Color.white.opacity(0.16),
        text: Color(hex: 0xFAFAFA),
        text2: Color.white.opacity(0.58),
        text3: Color.white.opacity(0.32),
        accentSoft: Color(hex: 0x2563EB).opacity(0.22),
        accentTint: Color(hex: 0x2563EB).opacity(0.14),
        scrim: Color.black.opacity(0.55)
    )

    static let light = PhysiqueColors(
        bg: Color(hex: 0xF3F3F5),
        surface: Color.white,
        surface2: Color(hex: 0xEDEDF1),
        surface3: Color(hex: 0xE4E4EA),
        hairline: Color.black.opacity(0.08),
        hairlineStrong: Color.black.opacity(0.14),
        text: Color(hex: 0x0A0A0C),
        text2: Color(red: 12/255, green: 12/255, blue: 16/255).opacity(0.56),
        text3: Color(red: 12/255, green: 12/255, blue: 16/255).opacity(0.34),
        accentSoft: Color(hex: 0x2563EB).opacity(0.12),
        accentTint: Color(hex: 0x2563EB).opacity(0.08),
        scrim: Color(red: 20/255, green: 20/255, blue: 28/255).opacity(0.32)
    )

    static func current(for scheme: ColorScheme) -> PhysiqueColors {
        scheme == .dark ? .dark : .light
    }
}

// MARK: - Color from Hex
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Environment Key
private struct PhysiqueColorsKey: EnvironmentKey {
    static let defaultValue = PhysiqueColors.dark
}

extension EnvironmentValues {
    var theme: PhysiqueColors {
        get { self[PhysiqueColorsKey.self] }
        set { self[PhysiqueColorsKey.self] = newValue }
    }
}
