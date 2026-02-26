import Foundation

@MainActor
final class RateLimitService {
    private var refreshTimer: Timer?
    private var onUpdate: ((UsageData) -> Void)?
    private var isFetching = false

    private static let cacheFilePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.claude/usage-cache.json"
    }()

    private static let refreshInterval: TimeInterval = 60 // 1 minute

    func start(onUpdate: @escaping (UsageData) -> Void) {
        self.onUpdate = onUpdate

        // Load cached data first
        if let cached = loadCache() {
            onUpdate(cached.usage)
        }

        // Fetch fresh data
        fetch()

        // Schedule periodic refresh
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetch()
            }
        }
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
        isFetching = true

        Task { [weak self] in
            let usage = await Self.fetchUsage()
            guard let self else { return }
            self.isFetching = false
            if let usage {
                self.saveCache(usage: usage)
                self.onUpdate?(usage)
            }
            completion?()
        }
    }

    // MARK: - OAuth API

    nonisolated private static func fetchUsage() async -> UsageData? {
        guard let token = getOAuthToken() else { return nil }

        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        guard var usage = try? JSONDecoder().decode(UsageData.self, from: data) else {
            return nil
        }
        usage.fetchedAt = Date()
        return usage
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
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let json = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !json.isEmpty else {
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
