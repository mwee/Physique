import SwiftUI
import Charts

struct LineChartView: View {
    let data: [Double]
    var height: CGFloat = 96
    var showArea: Bool = true
    var showDot: Bool = true
    var strokeColor: Color = .accent

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(strokeColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                if showArea {
                    AreaMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [strokeColor.opacity(0.26), strokeColor.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                if showDot && index == data.count - 1 {
                    PointMark(
                        x: .value("Index", index),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(strokeColor)
                    .symbolSize(40)
                }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: height)
    }
}
