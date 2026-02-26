import SwiftUI
import Charts

struct HourlyHeatmapView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity by Hour")
                    .font(.headline)
                Spacer()
                if let peak = peakHour {
                    Text("Peak: \(peak.hourLabel) (\(peak.count) sessions)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Chart(viewModel.hourlyActivityPoints) { point in
                BarMark(
                    x: .value("Hour", point.hourLabel),
                    y: .value("Sessions", point.count)
                )
                .foregroundStyle(barColor(for: point))
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var peakHour: HourlyActivityPoint? {
        viewModel.hourlyActivityPoints.max(by: { $0.count < $1.count })
    }

    private var maxCount: Int {
        viewModel.hourlyActivityPoints.map(\.count).max() ?? 1
    }

    private func barColor(for point: HourlyActivityPoint) -> Color {
        let intensity = maxCount > 0 ? Double(point.count) / Double(maxCount) : 0
        return Color.purple.opacity(0.2 + intensity * 0.8)
    }
}
