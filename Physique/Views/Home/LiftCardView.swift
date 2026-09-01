import SwiftUI

/// Home lift tile: the lift, its rolling-best e1RM, and a sparkline. With
/// three or more real points the line is the rolling trend; before that it's
/// a gentle rise into the current number — a motivational placeholder, not data.
struct LiftCardView: View {
    @Environment(\.theme) var theme
    let title: String
    let snapshot: LiftStatsService.Snapshot
    /// Used when the stream is empty — the max entered at plan setup.
    var fallbackValue: Double? = nil

    /// Real trend needs at least this many points with some movement.
    static let minTrendPoints = 3

    private var value: Double? { snapshot.value ?? fallbackValue }

    private var realTrend: [Double]? {
        let series = snapshot.rolling.suffix(10).map(\.value)
        guard series.count >= Self.minTrendPoints,
              let lo = series.min(), let hi = series.max(), hi > lo else { return nil }
        return series
    }

    /// Placeholder rise ending at the current value (~6% climb over the tile).
    private func placeholderRise(to value: Double) -> [Double] {
        [0.94, 0.955, 0.965, 0.98, 0.985, 1.0].map { value * $0 }
    }

    var body: some View {
        VStack(spacing: Spacing.s1) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(theme.text3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let value {
                Text(WeightFormatter.format(value))
                    .font(.system(size: 22, weight: .heavy))
                    .monospacedDigit()
                    .tracking(-0.5)
                    .foregroundStyle(snapshot.isStale ? theme.text3 : theme.text)
            } else {
                Text("Add")
                    .font(.system(size: TypeScale.sub, weight: .bold))
                    .foregroundStyle(Color.accent)
                    .frame(height: 26)
            }

            if let delta = snapshot.delta30 {
                Text("\(delta > 0 ? "+" : "\u{2212}")\(WeightFormatter.format(abs(delta))) \u{00B7} 30d")
                    .font(.system(size: 9.5, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(delta > 0 ? Color.successGreen : theme.text3)
                    .lineLimit(1)
            }

            if let trend = realTrend {
                SparklineView(data: trend, height: 18)
                    .opacity(snapshot.isStale ? 0.5 : 1)
                    .padding(.top, Spacing.s1)
            } else if let value {
                SparklineView(data: placeholderRise(to: value), height: 18, goldDotOnPeak: false)
                    .opacity(0.7)
                    .padding(.top, Spacing.s1)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, Spacing.s3)
        .padding(.horizontal, Spacing.s2)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md)
                .stroke(theme.hairline, lineWidth: 1)
        )
    }
}
