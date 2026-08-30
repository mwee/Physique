import SwiftUI

/// Tiny inline trend line for stat tiles and list rows.
/// The end dot renders gold when the latest value is the all-time high (a PR).
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
        guard data.count >= 2,
              let min = data.min(), let max = data.max() else { return [] }
        let range = max - min == 0 ? 1 : max - min
        let inset: CGFloat = 3
        let stepX = (size.width - 2 * inset) / CGFloat(data.count - 1)
        return data.enumerated().map { index, value in
            CGPoint(
                x: inset + CGFloat(index) * stepX,
                y: size.height - inset - CGFloat((value - min) / range) * (size.height - 2 * inset)
            )
        }
    }
}
