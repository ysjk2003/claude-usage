import SwiftUI

struct PopoverView: View {
    @ObservedObject var viewModel: StatsViewModel
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
                Button(action: { viewModel.refreshRateLimit() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                        .animation(
                            viewModel.isRefreshing
                                ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                : .default,
                            value: viewModel.isRefreshing
                        )
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isRefreshing)
            }

            Divider()

            // Usage / Rate Limit
            if viewModel.usageData != nil {
                usageSection()
            } else {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading usage data...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Divider()

            // Actions
            HStack {
                Spacer()
                Button(action: onQuit) {
                    Text("Quit")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .frame(width: 300)
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
}
