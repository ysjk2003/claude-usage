import Foundation

// MARK: - Daily Activity Chart Data
struct DailyActivityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    let metric: ActivityMetric
}

enum ActivityMetric: String, CaseIterable, Identifiable {
    case messages = "Messages"
    case sessions = "Sessions"
    case toolCalls = "Tool Calls"

    var id: String { rawValue }
}

// MARK: - Token Usage Chart Data
struct DailyTokenPoint: Identifiable {
    let id = UUID()
    let date: Date
    let tokens: Int
    let model: String
}

// MARK: - Model Breakdown Data
struct ModelBreakdownItem: Identifiable {
    let id = UUID()
    let modelName: String
    let displayName: String
    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheCreationTokens: Int

    var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheCreationTokens
    }
}

// MARK: - Hourly Activity Data
struct HourlyActivityPoint: Identifiable {
    let id = UUID()
    let hour: Int
    let count: Int

    var hourLabel: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return "\(h)\(suffix)"
    }
}

// MARK: - Helpers
struct ModelDisplayNames {
    static func displayName(for model: String) -> String {
        if model.contains("opus-4-6") { return "Opus 4.6" }
        if model.contains("opus-4-5") { return "Opus 4.5" }
        if model.contains("sonnet-4-6") { return "Sonnet 4.6" }
        if model.contains("sonnet-4-5") { return "Sonnet 4.5" }
        if model.contains("haiku-4-5") { return "Haiku 4.5" }
        if model.contains("haiku") { return "Haiku" }
        if model.contains("sonnet") { return "Sonnet" }
        if model.contains("opus") { return "Opus" }
        return model
    }

    static func color(for model: String) -> String {
        if model.contains("opus-4-6") { return "purple" }
        if model.contains("opus-4-5") { return "indigo" }
        if model.contains("sonnet-4-6") { return "blue" }
        if model.contains("sonnet-4-5") { return "cyan" }
        if model.contains("haiku") { return "mint" }
        return "gray"
    }
}

struct TokenFormatter {
    static func format(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.1fB", Double(tokens) / 1_000_000_000)
        } else if tokens >= 1_000_000 {
            return String(format: "%.1fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.0fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }

    static func formatCompact(_ tokens: Int) -> String {
        if tokens >= 1_000_000_000 {
            return String(format: "%.1fB", Double(tokens) / 1_000_000_000)
        } else if tokens >= 1_000_000 {
            return String(format: "%.0fM", Double(tokens) / 1_000_000)
        } else if tokens >= 1_000 {
            return String(format: "%.0fK", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }
}
