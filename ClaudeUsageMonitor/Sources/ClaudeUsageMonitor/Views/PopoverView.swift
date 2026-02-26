import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: StatsViewModel
    var onOpenDashboard: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.purple)
                    .font(.title2)
                Text("Claude Usage")
                    .font(.headline)
                Spacer()
                if let updated = viewModel.lastUpdated {
                    Text(updated, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Usage / Rate Limit
            if viewModel.usageData != nil {
                usageSection()
                Divider()
            }

            if let stats = viewModel.statsData {
                // Today's Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let today = viewModel.todayActivity {
                        HStack(spacing: 16) {
                            miniStat(icon: "message.fill", label: "Messages", value: "\(today.messageCount)")
                            miniStat(icon: "rectangle.stack.fill", label: "Sessions", value: "\(today.sessionCount)")
                            miniStat(icon: "wrench.fill", label: "Tools", value: "\(today.toolCallCount)")
                        }
                    } else {
                        Text("No activity yet today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if viewModel.todayTokens > 0 {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("Tokens: \(TokenFormatter.format(viewModel.todayTokens))")
                                .font(.caption)
                        }
                    }
                }

                Divider()

                // Overall Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("All Time")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        miniStat(icon: "rectangle.stack.fill", label: "Sessions", value: "\(stats.totalSessions)")
                        miniStat(icon: "message.fill", label: "Messages", value: formatNumber(stats.totalMessages))
                    }

                    HStack {
                        Image(systemName: "cpu")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("Total Tokens: \(TokenFormatter.format(viewModel.totalTokens))")
                            .font(.caption)
                    }

                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("Longest Session: \(stats.longestSession.durationFormatted) (\(stats.longestSession.messageCount) msgs)")
                            .font(.caption)
                    }
                }

                Divider()

                // Model breakdown
                VStack(alignment: .leading, spacing: 6) {
                    Text("Models")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(viewModel.modelBreakdownItems) { item in
                        HStack {
                            Circle()
                                .fill(colorForModel(item.modelName))
                                .frame(width: 8, height: 8)
                            Text(item.displayName)
                                .font(.caption)
                            Spacer()
                            Text(TokenFormatter.format(item.totalTokens))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            }

            Divider()

            // Actions
            HStack {
                Button(action: onOpenDashboard) {
                    Label("Open Dashboard", systemImage: "macwindow")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)

                Spacer()

                Button(action: onQuit) {
                    Text("Quit")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func usageSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Usage")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if let fetched = viewModel.usageData?.fetchedAt {
                    Text(fetched, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let bucket = viewModel.fiveHourBucket {
                usageRow(label: "5h Limit", bucket: bucket)
            }
            if let bucket = viewModel.sevenDayBucket {
                usageRow(label: "7d Limit", bucket: bucket)
            }
        }
    }

    private func usageRow(label: String, bucket: UsageBucket) -> some View {
        let pct = bucket.utilization
        let barColor: Color = pct >= 90 ? .red : pct >= 70 ? .orange : .green

        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                Text("\(Int(pct))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(barColor)
                Spacer()
                Text("resets in \(bucket.resetTimeFormatted)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor.opacity(0.7))
                        .frame(width: geo.size.width * min(1, pct / 100), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func miniStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .foregroundStyle(.purple)
                .font(.caption)
            Text(value)
                .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 {
            return String(format: "%.1fK", Double(n) / 1000)
        }
        return "\(n)"
    }

    private func colorForModel(_ model: String) -> Color {
        if model.contains("opus-4-6") { return .purple }
        if model.contains("opus-4-5") { return .indigo }
        if model.contains("sonnet") { return .blue }
        if model.contains("haiku") { return .mint }
        return .gray
    }
}
