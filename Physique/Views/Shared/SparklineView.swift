import SwiftUI

/// Tiny inline trend line for stat tiles and list rows.
/// The end dot renders gold when the latest value is the all-time high (a PR).
/// A single value draws as a flat line; a flat series sits mid-height rather
/// than on the baseline so it never reads as an empty placeholder.
struct SparklineView: View {
    let data: [Double]
    var height: CGFloat = 20
    var stroke: Color = .accent
    var goldDotOnPeak: Bool = true

    var body: some View {
        GeometryReader { geo in
            let points = normalizedPoints(in: geo.size)
            if points.count >= 2 {
                Path { path in
                    path.move(to: points[0])
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(stroke, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                if let last = points.last {
                    Circle()
                        .fill(isPeak && goldDotOnPeak ? Color.prGold : stroke)
                        .frame(width: 5, height: 5)
                        .position(last)
                }
            }
        }
        .frame(height: height)
    }

    private var isPeak: Bool {
        guard let last = data.last, let peak = data.max() else { return false }
        return last >= peak
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard let min = data.min(), let max = data.max() else { return [] }
        let series = data.count == 1 ? [data[0], data[0]] : data
        let range = max - min
        let inset: CGFloat = 3
        let stepX = (size.width - 2 * inset) / CGFloat(series.count - 1)
        return series.enumerated().map { index, value in
            let t: CGFloat = range == 0 ? 0.5 : CGFloat((value - min) / range)
            return CGPoint(
                x: inset + CGFloat(index) * stepX,
                y: size.height - inset - t * (size.height - 2 * inset)
            )
        }
    }
}
