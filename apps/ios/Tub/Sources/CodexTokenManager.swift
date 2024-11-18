//
//  CodexTokenManager.swift
//  Tub
//
//  Created by polarzero on 18/11/2024.
//

import Foundation

class CodexTokenManager: ObservableObject {
    static let shared = CodexTokenManager()
    
    private let tokenExpiration: TimeInterval = 60 * 60 // 1h, minimum 10 min
    private let maxRetryAttempts = 3
    private var retryCount = 0

    private var refreshTimer: Timer?
    
    private init() {}

    public func handleUserSession() async throws {
        refreshToken()
    }
    
    private func stopTokenRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        retryCount = 0
    }

    private func refreshToken() {
        Task {
            do {
                let codexToken = try await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
                CodexNetwork.initialize(apiKey: codexToken.0)
                retryCount = 0 // Reset retry count on success
                
                // Parse the expiry string to get the expiration time
                if let expiryDate = ISO8601DateFormatter().date(from: codexToken.1) {
                    let timeUntilExpiry = expiryDate.timeIntervalSinceNow
                    
                    // If expiry is less than 10 minutes away, throw an error
                    if timeUntilExpiry < 60 * 10 {
                        throw NSError(domain: "CodexTokenManager", code: 1, userInfo: [
                            NSLocalizedDescriptionKey: "Token expiration time too short"
                        ])
                    }
                    
                    // Set refresh timer to 5 minutes before expiration
                    refreshTimer?.invalidate()
                    let refreshTime = timeUntilExpiry - 60 * 5 // 5 minutes in seconds
                    refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: false) { [weak self] _ in
                        self?.refreshToken()
                    }
                }
                
                print("Successfully refreshed Codex token")
            } catch {
                print("Failed to refresh Codex token: \(error)")
                
                // Retry logic
                if retryCount < maxRetryAttempts {
                    retryCount += 1
                    let delay = Double(retryCount) * 2 // Exponential backoff
                    
                    // Schedule retry after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                        self?.refreshToken()
                    }
                    print("Scheduling retry attempt \(retryCount) after \(delay) seconds")
                }
            }
        }
    }

    deinit {
        stopTokenRefresh()
    }
}
