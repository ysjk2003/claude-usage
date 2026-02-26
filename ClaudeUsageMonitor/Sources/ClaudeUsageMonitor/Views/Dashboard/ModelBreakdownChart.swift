import SwiftUI
import Charts

struct ModelBreakdownChart: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Usage Breakdown")
                .font(.headline)

            HStack(spacing: 20) {
                // Donut chart
                Chart(viewModel.modelBreakdownItems) { item in
                    SectorMark(
                        angle: .value("Tokens", item.totalTokens),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(colorForModel(item.modelName))
                    .cornerRadius(4)
                }
                .frame(width: 160, height: 160)
                .overlay {
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(TokenFormatter.format(viewModel.totalTokens))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                    }
                }

                // Detail table
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.modelBreakdownItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(colorForModel(item.modelName))
                                    .frame(width: 10, height: 10)
                                Text(item.displayName)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(TokenFormatter.format(item.totalTokens))
                                    .font(.subheadline.monospacedDigit().weight(.semibold))
                            }

                            HStack(spacing: 12) {
                                tokenDetail("Input", tokens: item.inputTokens)
                                tokenDetail("Output", tokens: item.outputTokens)
                                tokenDetail("Cache Read", tokens: item.cacheReadTokens)
                                tokenDetail("Cache Write", tokens: item.cacheCreationTokens)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func tokenDetail(_ label: String, tokens: Int) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Text(TokenFormatter.format(tokens))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func colorForModel(_ model: String) -> Color {
        if model.contains("opus-4-6") { return .purple }
        if model.contains("opus-4-5") { return .indigo }
        if model.contains("sonnet-4-6") { return .blue }
        if model.contains("sonnet-4-5") { return .cyan }
        if model.contains("haiku") { return .mint }
        return .gray
    }
}
