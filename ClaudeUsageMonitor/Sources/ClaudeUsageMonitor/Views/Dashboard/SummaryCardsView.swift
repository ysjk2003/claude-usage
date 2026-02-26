import SwiftUI

struct SummaryCardsView: View {
    @ObservedObject var viewModel: StatsViewModel

    var body: some View {
        if let stats = viewModel.statsData {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                StatCardView(
                    title: "Total Sessions",
                    value: "\(stats.totalSessions)",
                    icon: "rectangle.stack.fill",
                    color: .purple
                )

                StatCardView(
                    title: "Total Messages",
                    value: formatNumber(stats.totalMessages),
                    icon: "message.fill",
                    color: .blue
                )

                StatCardView(
                    title: "Total Tokens",
                    value: TokenFormatter.format(viewModel.totalTokens),
                    icon: "cpu",
                    color: .orange
                )

                StatCardView(
                    title: "Longest Session",
                    value: stats.longestSession.durationFormatted,
                    icon: "timer",
                    subtitle: "\(stats.longestSession.messageCount) messages",
                    color: .green
                )

                StatCardView(
                    title: "Since",
                    value: formatStartDate(stats.firstSessionDate),
                    icon: "calendar",
                    subtitle: "\(daysSinceStart(stats.firstSessionDate)) days",
                    color: .pink
                )
            }
        }
    }

    private func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private func formatStartDate(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: iso) else { return iso.prefix(10).description }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }

    private func daysSinceStart(_ iso: String) -> Int {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: iso) else { return 0 }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
    }
}
