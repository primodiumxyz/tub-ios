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
    private let maxRetryAttempts = 2
    private var retryCount = 0
    @Published var fetchFailed = false
    @Published var isReady = false

    private var refreshTimer: Timer?
    
    private init() {}

    public func handleUserSession() {
        isReady = false
        fetchFailed = false
        retryCount = 0
        refreshToken()
    }
    
    private func stopTokenRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        retryCount = 0
    }

    private func refreshToken() {
        Task (priority: .high) {
            do {
                fetchFailed = false
                let codexToken = try await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
                CodexNetwork.initialize(apiKey: codexToken.0)
                retryCount = 0 
                isReady = true
                
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
                
            } catch {
                // Retry logic
                if retryCount < maxRetryAttempts {
                    retryCount += 1
                    let delay = Double(retryCount) * 2 // Exponential backoff
                    Task (priority: .low) {
                        print("Fetch failed, retrying...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        self.refreshToken()
                    }
                } else {
                    print("Fetch failed, giving up")
                    fetchFailed = true
                }
            }
        }
    }

    deinit {
        stopTokenRefresh()
    }
}
