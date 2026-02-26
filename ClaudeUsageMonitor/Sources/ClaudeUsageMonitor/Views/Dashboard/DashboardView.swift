import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.purple)
                        .font(.title2)
                    Text("Claude Usage Dashboard")
                        .font(.title2.weight(.bold))
                    Spacer()
                    if let updated = viewModel.lastUpdated {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 6, height: 6)
                            Text("Updated \(updated, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if viewModel.statsData != nil {
                    // Summary Cards
                    SummaryCardsView(viewModel: viewModel)
                        .padding(.horizontal)

                    // Charts in 2-column grid
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 16) {
                            DailyActivityChart(viewModel: viewModel)
                            TokenUsageChart(viewModel: viewModel)
                        }
                        VStack(spacing: 16) {
                            ModelBreakdownChart(viewModel: viewModel)
                            HourlyHeatmapView(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                        Text("Failed to load data")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Retry") {
                            viewModel.loadData()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    ProgressView("Loading stats...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                }

                Spacer(minLength: 16)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
