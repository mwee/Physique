import SwiftUI
import Charts

struct BarChartView: View {
    let data: [Double]
    var height: CGFloat = 96
    var highlightLast: Bool = true

    var body: some View {
        Chart {
            ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                BarMark(
                    x: .value("Index", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    highlightLast && index == data.count - 1
                        ? Color.accent
                        : Color(hex: 0x29292F)
                )
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: height)
    }
}
