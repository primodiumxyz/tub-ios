//
//  CodexTokenManager.swift
//  Tub
//
//  Created by polarzero on 18/11/2024.
//

import Foundation
import SwiftUI

// Add this structure above the CodexTokenManager class
struct CodexTokenData: RawRepresentable, Codable {
    let token: String
    let expiry: String

    init?(rawValue: String) {
        let components = rawValue.components(separatedBy: " and ")
        guard components.count == 2 else { return nil }
        self.token = components[0]
        self.expiry = components[1]
    }

    var rawValue: String {
        return "\(token) and \(expiry)"
    }

    init(token: String, expiry: String) {
        self.token = token
        self.expiry = expiry
    }
}

class CodexTokenManager: ObservableObject {
    static let shared = CodexTokenManager()

    private let tokenExpiration: TimeInterval = 60 * 60 * 24  // 24h
    private let maxRetryAttempts = 2
    private var retryCount = 0
    @Published var fetchFailed = false
    @Published var isReady = false
    @AppStorage("codexToken") private var localCodexTokenData: CodexTokenData?
    private var localCodexToken: (String, String)? {
        get {
            guard let data = localCodexTokenData else { return nil }
            return (data.token, data.expiry)
        }
        set {
            if let newValue = newValue {
                localCodexTokenData = CodexTokenData(token: newValue.0, expiry: newValue.1)
            }
            else {
                localCodexTokenData = nil
            }
        }
    }

    private var refetchTimer: Timer?
    private var isRefreshing = false

    private init() {}

    public func handleUserSession() async {
        await MainActor.run {
            isReady = false
            fetchFailed = false
            retryCount = 0
        }
        await refreshToken()
    }

    private func stopTokenRefresh() {
        refetchTimer?.invalidate()
        refetchTimer = nil
        retryCount = 0
    }
    private let formatter = { () -> ISO8601DateFormatter in
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private func fetchToken() async throws -> (String, String) {
        return try! await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
    }

    private func refreshToken() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await MainActor.run {
            fetchFailed = false
        }
        do {
            var codexToken = try await fetchToken()

            if let expiryDate = formatter.date(from: codexToken.1) {
                let timeUntilExpiry = expiryDate.timeIntervalSinceNow
                print("time until expiry:", timeUntilExpiry)

                // Ensure we're not scheduling in the past
                let refreshTimeInterval = min(timeUntilExpiry - 300, timeUntilExpiry * 0.9)
                if refreshTimeInterval > 0 {
                    await MainActor.run {
                        // Invalidate existing timer first
                        refetchTimer?.invalidate()
                        refetchTimer = Timer(
                            timeInterval: refreshTimeInterval,
                            target: self,
                            selector: #selector(refreshTokenTimerFired),
                            userInfo: nil,
                            repeats: false
                        )
                        RunLoop.main.add(refetchTimer!, forMode: .common)
                    }
                }
                else {
                    // If we're too close to expiry or past it, refresh immediately

                    print("refreshing")
                    localCodexToken = nil
                    codexToken = try await fetchToken()
                }
            }

            CodexNetwork.initialize(apiKey: codexToken.0)
            self.localCodexToken = codexToken
            self.retryCount = 0
            DispatchQueue.main.async {
                self.isReady = true
            }

        }
        catch {
            if retryCount < maxRetryAttempts {
                retryCount += 1
                let delay = Double(retryCount) * 2  // Exponential backoff
                Task(priority: .low) {
                    print("Fetch failed, retrying...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    await self.refreshToken()
                }
            }
            else {
                print("Fetch failed, giving up")
                DispatchQueue.main.async {
                    self.fetchFailed = true
                }
            }
        }
    }

    deinit {
        stopTokenRefresh()
    }

    @objc private func refreshTokenTimerFired() {
        Task { await refreshToken() }
    }
}
