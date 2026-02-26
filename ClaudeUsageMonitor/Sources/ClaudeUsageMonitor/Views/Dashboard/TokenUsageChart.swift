import SwiftUI
import Charts

struct TokenUsageChart: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Token Usage by Model")
                .font(.headline)

            Chart {
                ForEach(viewModel.dailyTokenPoints) { point in
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Tokens", point.tokens),
                        stacking: .standard
                    )
                    .foregroundStyle(by: .value("Model", point.model))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale(modelColorMapping)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text(TokenFormatter.formatCompact(intVal))
                        }
                    }
                }
            }
            .chartLegend(position: .top, alignment: .trailing)
            .frame(height: 200)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var modelColorMapping: KeyValuePairs<String, Color> {
        let models = Set(viewModel.dailyTokenPoints.map(\.model)).sorted()
        var pairs: [(String, Color)] = []
        for model in models {
            if model.contains("4.6") {
                pairs.append((model, .purple))
            } else if model.contains("4.5") {
                pairs.append((model, .indigo))
            } else {
                pairs.append((model, .gray))
            }
        }
        // KeyValuePairs requires literal initialization, so we use a switch
        switch pairs.count {
        case 1:
            return [pairs[0].0: pairs[0].1]
        case 2:
            return [pairs[0].0: pairs[0].1, pairs[1].0: pairs[1].1]
        case 3:
            return [pairs[0].0: pairs[0].1, pairs[1].0: pairs[1].1, pairs[2].0: pairs[2].1]
        default:
            return ["Unknown": .gray]
        }
    }
}
