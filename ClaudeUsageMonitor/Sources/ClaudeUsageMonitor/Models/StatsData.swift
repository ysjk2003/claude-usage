import Foundation

// MARK: - Root
struct StatsData: Codable {
    let version: Int
    let lastComputedDate: String
    let dailyActivity: [DailyActivity]
    let dailyModelTokens: [DailyModelTokens]
    let modelUsage: [String: ModelUsage]
    let totalSessions: Int
    let totalMessages: Int
    let longestSession: LongestSession
    let firstSessionDate: String
    let hourCounts: [String: Int]
    let totalSpeculationTimeSavedMs: Int?
}

// MARK: - Daily Activity
struct DailyActivity: Codable, Identifiable {
    let date: String
    let messageCount: Int
    let sessionCount: Int
    let toolCallCount: Int

    var id: String { date }

    var parsedDate: Date? {
        Self.dateFormatter.date(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Daily Model Tokens
struct DailyModelTokens: Codable, Identifiable {
    let date: String
    let tokensByModel: [String: Int]

    var id: String { date }

    var parsedDate: Date? {
        Self.dateFormatter.date(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

// MARK: - Model Usage
struct ModelUsage: Codable {
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadInputTokens: Int
    let cacheCreationInputTokens: Int
    let webSearchRequests: Int?
    let costUSD: Double?
    let contextWindow: Int?
    let maxOutputTokens: Int?

    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadInputTokens + cacheCreationInputTokens
    }
}

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

// MARK: - Longest Session
struct LongestSession: Codable {
    let sessionId: String
    let duration: Int // milliseconds
    let messageCount: Int
    let timestamp: String

    var durationFormatted: String {
        let totalSeconds = duration / 1000
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
