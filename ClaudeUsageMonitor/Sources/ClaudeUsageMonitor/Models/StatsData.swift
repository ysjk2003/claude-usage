import Foundation

// MARK: - Rate Limit Usage (from OAuth API)
struct UsageBucket: Codable {
    let utilization: Double   // percentage 0-100
    let resets_at: String     // ISO 8601 timestamp

    var resetsAtDate: Date? {
        ISO8601DateFormatter().date(from: resets_at)
            ?? Self.fractionalFormatter.date(from: resets_at)
    }

    var resetTimeRemaining: TimeInterval {
        guard let reset = resetsAtDate else { return 0 }
        return max(0, reset.timeIntervalSince(Date()))
    }

    var resetTimeFormatted: String {
        let remaining = resetTimeRemaining
        if remaining <= 0 { return "now" }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

struct UsageData: Codable {
    let five_hour: UsageBucket?
    let seven_day: UsageBucket?
    var fetchedAt: Date?
}

struct UsageCache: Codable {
    var usage: UsageData
    var lastChecked: Date
}
