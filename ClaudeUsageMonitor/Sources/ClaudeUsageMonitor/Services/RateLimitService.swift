import Foundation
import os

private let logger = Logger(subsystem: "com.claudeusage.monitor", category: "RateLimitService")

@MainActor
final class RateLimitService {
    private var refreshTimer: Timer?
    private var onUpdate: ((UsageData) -> Void)?
    private var isFetching = false
    private var retryAfterDate: Date?

    private static let cacheFilePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/usage-cache.json"
    }()

    private static let defaultRefreshInterval: TimeInterval = 300 // 5 minutes

    func start(onUpdate: @escaping (UsageData) -> Void) {
        self.onUpdate = onUpdate

        // Load cached data first
        if let cached = loadCache() {
            onUpdate(cached.usage)
        }

        // Fetch fresh data
        fetch()

        // Schedule periodic refresh
        scheduleNextRefresh()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        onUpdate = nil
    }

    func fetch(completion: (() -> Void)? = nil) {
        guard !isFetching else {
            completion?()
            return
        }

        // Respect Retry-After
        if let retryAfter = retryAfterDate, Date() < retryAfter {
            logger.info("Skipping fetch, retry-after not yet elapsed")
            completion?()
            return
        }

        isFetching = true

        Task { [weak self] in
            let result = await Self.fetchUsage()
            self?.isFetching = false
            switch result {
            case .success(let usage):
                self?.retryAfterDate = nil
                self?.saveCache(usage: usage)
                self?.onUpdate?(usage)
            case .rateLimited(let retryAfter):
                let delay = retryAfter ?? 300
                self?.retryAfterDate = Date().addingTimeInterval(TimeInterval(delay))
                logger.warning("Rate limited, backing off for \(delay)s")
            case .failure:
                break
            }
            self?.scheduleNextRefresh()
            completion?()
        }
    }

    private func scheduleNextRefresh() {
        refreshTimer?.invalidate()
        let interval: TimeInterval
        if let retryAfter = retryAfterDate {
            interval = max(retryAfter.timeIntervalSinceNow, Self.defaultRefreshInterval)
        } else {
            interval = Self.defaultRefreshInterval
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.fetch()
            }
        }
    }

    // MARK: - OAuth API

    private enum FetchResult {
        case success(UsageData)
        case rateLimited(retryAfter: Int?)
        case failure
    }

    nonisolated private static func fetchUsage() async -> FetchResult {
        guard let token = getOAuthToken() else {
            logger.error("OAuth token retrieval failed")
            return .failure
        }

        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return .failure }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 10

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            return .failure
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type")
            return .failure
        }

        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            return .rateLimited(retryAfter: retryAfter)
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "(non-utf8)"
            logger.error("API returned status \(httpResponse.statusCode): \(body)")
            return .failure
        }

        do {
            var usage = try JSONDecoder().decode(UsageData.self, from: data)
            usage.fetchedAt = Date()
            return .success(usage)
        } catch {
            logger.error("JSON decoding failed: \(error.localizedDescription)")
            return .failure
        }
    }

    nonisolated private static func getOAuthToken() -> String? {
        // Read from macOS Keychain
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.error("Keychain process launch failed: \(error.localizedDescription)")
            return nil
        }

        guard process.terminationStatus == 0 else {
            logger.error("Keychain lookup failed with exit code \(process.terminationStatus)")
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !json.isEmpty else {
            logger.error("Keychain returned empty data")
            return nil
        }

        // Parse JSON to extract accessToken
        struct Credentials: Decodable {
            let claudeAiOauth: OAuthInfo?
            struct OAuthInfo: Decodable {
                let accessToken: String
            }
        }

        guard let credData = json.data(using: .utf8),
              let creds = try? JSONDecoder().decode(Credentials.self, from: credData),
              let token = creds.claudeAiOauth?.accessToken else {
            logger.error("Failed to parse OAuth credentials from keychain data")
            return nil
        }

        return token
    }

    // MARK: - Cache

    private func loadCache() -> UsageCache? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: Self.cacheFilePath)) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(UsageCache.self, from: data)
    }

    private func saveCache(usage: UsageData) {
        let cache = UsageCache(usage: usage, lastChecked: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(cache) else { return }
        try? data.write(to: URL(fileURLWithPath: Self.cacheFilePath), options: .atomic)
    }
}
