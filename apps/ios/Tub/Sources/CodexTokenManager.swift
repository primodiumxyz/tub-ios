//
//  CodexTokenManager.swift
//  Tub
//
//  Created by polarzero on 18/11/2024.
//

import Foundation
import SwiftUI
import TubAPI

struct CodexTokenData {
    var token: String
    var expiry: String
}
class CodexTokenManager: ObservableObject {
    static let shared = CodexTokenManager()

    private let tokenExpiration: TimeInterval = 60 * 60  // 1h
    private let maxRetryAttempts = 2
    private var retryCount = 0
    @Published var fetchFailed = false
    @Published var isReady = false

    private var refetchTimer: Timer?
    private var isRefreshing = false

    private func stopTokenRefresh() {
        Task { @MainActor in
            refetchTimer?.invalidate()
            refetchTimer = nil
            retryCount = 0
        }
    }

    private let formatter = { () -> ISO8601DateFormatter in
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private func fetchToken(hard: Bool? = false) async throws -> CodexTokenData {
        do {
            return try await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
        }
        catch {
            throw error
        }
    }

    func refreshToken(hard: Bool? = false) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        await MainActor.run {
            isReady = false
            fetchFailed = false
        }
        do {
            let codexToken = try await fetchToken(hard: hard ?? false)

            if let expiryDate = formatter.date(from: codexToken.expiry) {
                let timeUntilExpiry = expiryDate.timeIntervalSinceNow

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
            }

            await CodexNetwork.initialize(apiKey: codexToken.token)
            await MainActor.run {
                self.retryCount = 0
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
                    await self.refreshToken(hard: true)
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
