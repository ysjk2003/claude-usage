import Foundation
import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    // MARK: - Raw Data
    @Published var statsData: StatsData?
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    // MARK: - Usage / Rate Limit
    @Published var usageData: UsageData?

    // MARK: - Chart Data
    @Published var dailyActivityPoints: [DailyActivityPoint] = []
    @Published var dailyTokenPoints: [DailyTokenPoint] = []
    @Published var modelBreakdownItems: [ModelBreakdownItem] = []
    @Published var hourlyActivityPoints: [HourlyActivityPoint] = []

    // MARK: - Computed
    var todayActivity: DailyActivity? {
        let today = Self.dateFormatter.string(from: Date())
        return statsData?.dailyActivity.first(where: { $0.date == today })
    }

    var todayTokens: Int {
        let today = Self.dateFormatter.string(from: Date())
        return statsData?.dailyModelTokens
            .first(where: { $0.date == today })?
            .tokensByModel.values.reduce(0, +) ?? 0
    }

    var totalTokens: Int {
        statsData?.modelUsage.values.reduce(0) { $0 + $1.totalTokens } ?? 0
    }

    var menuBarText: String {
        let t = todayTokens
        if t == 0 { return "" }
        return TokenFormatter.formatCompact(t)
    }

    // MARK: - Usage Computed
    var fiveHourBucket: UsageBucket? { usageData?.five_hour }
    var sevenDayBucket: UsageBucket? { usageData?.seven_day }

    // MARK: - Private
    private var fileWatcher: FileWatcherService?
    private var rateLimitService: RateLimitService?
    private static let statsFilePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/stats-cache.json"
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Lifecycle
    func startMonitoring() {
        loadData()
        fileWatcher = FileWatcherService(filePath: Self.statsFilePath) { [weak self] in
            Task { @MainActor [weak self] in
                self?.loadData()
            }
        }
        fileWatcher?.start()

        // Start rate limit monitoring
        let service = RateLimitService()
        rateLimitService = service
        service.start { [weak self] usage in
            self?.usageData = usage
        }
    }

    func stopMonitoring() {
        fileWatcher?.stop()
        fileWatcher = nil
        rateLimitService?.stop()
        rateLimitService = nil
    }

    func refreshRateLimit() {
        rateLimitService?.fetch()
    }

    // MARK: - Data Loading
    func loadData() {
        do {
            let url = URL(fileURLWithPath: Self.statsFilePath)
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(StatsData.self, from: data)
            self.statsData = decoded
            self.lastUpdated = Date()
            self.errorMessage = nil
            transformChartData(decoded)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Transformations
    private func transformChartData(_ stats: StatsData) {
        transformDailyActivity(stats.dailyActivity)
        transformDailyTokens(stats.dailyModelTokens)
        transformModelBreakdown(stats.modelUsage)
        transformHourlyActivity(stats.hourCounts)
    }

    private func transformDailyActivity(_ activities: [DailyActivity]) {
        var points: [DailyActivityPoint] = []
        for a in activities {
            guard let date = a.parsedDate else { continue }
            points.append(DailyActivityPoint(date: date, value: a.messageCount, metric: .messages))
            points.append(DailyActivityPoint(date: date, value: a.sessionCount, metric: .sessions))
            points.append(DailyActivityPoint(date: date, value: a.toolCallCount, metric: .toolCalls))
        }
        dailyActivityPoints = points
    }

    private func transformDailyTokens(_ dailyTokens: [DailyModelTokens]) {
        var points: [DailyTokenPoint] = []
        for dt in dailyTokens {
            guard let date = dt.parsedDate else { continue }
            for (model, tokens) in dt.tokensByModel {
                points.append(DailyTokenPoint(
                    date: date,
                    tokens: tokens,
                    model: ModelDisplayNames.displayName(for: model)
                ))
            }
        }
        dailyTokenPoints = points
    }

    private func transformModelBreakdown(_ usage: [String: ModelUsage]) {
        modelBreakdownItems = usage.map { (model, data) in
            ModelBreakdownItem(
                modelName: model,
                displayName: ModelDisplayNames.displayName(for: model),
                inputTokens: data.inputTokens,
                outputTokens: data.outputTokens,
                cacheReadTokens: data.cacheReadInputTokens,
                cacheCreationTokens: data.cacheCreationInputTokens
            )
        }.sorted { $0.totalTokens > $1.totalTokens }
    }

    private func transformHourlyActivity(_ hourCounts: [String: Int]) {
        hourlyActivityPoints = (0..<24).map { hour in
            HourlyActivityPoint(hour: hour, count: hourCounts["\(hour)"] ?? 0)
        }
    }
}
