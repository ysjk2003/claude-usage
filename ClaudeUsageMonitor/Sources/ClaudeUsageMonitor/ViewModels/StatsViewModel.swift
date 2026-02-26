import Foundation
import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    // MARK: - Usage / Rate Limit
    @Published var usageData: UsageData?
    @Published var lastUpdated: Date?
    @Published var isRefreshing: Bool = false

    // MARK: - Computed
    var fiveHourBucket: UsageBucket? { usageData?.five_hour }
    var sevenDayBucket: UsageBucket? { usageData?.seven_day }

    var menuBarText: String {
        guard let bucket = fiveHourBucket else { return "" }
        return "\(Int(bucket.utilization))%"
    }

    // MARK: - Private
    private var rateLimitService: RateLimitService?

    // MARK: - Lifecycle
    func startMonitoring() {
        let service = RateLimitService()
        rateLimitService = service
        service.start { [weak self] usage in
            self?.usageData = usage
            self?.lastUpdated = Date()
        }
    }

    func stopMonitoring() {
        rateLimitService?.stop()
        rateLimitService = nil
    }

    func refreshRateLimit() {
        isRefreshing = true
        rateLimitService?.fetch { [weak self] in
            self?.isRefreshing = false
        }
    }
}
