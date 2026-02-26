import SwiftUI
import Charts

struct DailyActivityChart: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var selectedMetric: ActivityMetric = .messages

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Activity")
                    .font(.headline)
                Spacer()
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(ActivityMetric.allCases) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }

            Chart {
                ForEach(filteredPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(gradientForMetric.opacity(0.3))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(colorForMetric)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(selectedMetric.rawValue, point.value)
                    )
                    .foregroundStyle(colorForMetric)
                    .symbolSize(16)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var filteredPoints: [DailyActivityPoint] {
        viewModel.dailyActivityPoints.filter { $0.metric == selectedMetric }
    }

    private var colorForMetric: Color {
        switch selectedMetric {
        case .messages: return .purple
        case .sessions: return .blue
        case .toolCalls: return .orange
        }
    }

    private var gradientForMetric: LinearGradient {
        LinearGradient(
            colors: [colorForMetric, colorForMetric.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
