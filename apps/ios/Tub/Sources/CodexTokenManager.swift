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
        let components = rawValue.components(separatedBy: "|")
        guard components.count == 2 else { return nil }
        self.token = components[0]
        self.expiry = components[1]
    }
    
    var rawValue: String {
        return "\(token)|\(expiry)"
    }
    
    init(token: String, expiry: String) {
        self.token = token
        self.expiry = expiry
    }
}

class CodexTokenManager: ObservableObject {
    static let shared = CodexTokenManager()
    
    private let tokenExpiration: TimeInterval = 60 * 60 // 1h, minimum 10 min
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
            } else {
                localCodexTokenData = nil
            }
        }
    }

    private var refreshTimer: Timer?
    
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
        refreshTimer?.invalidate()
        refreshTimer = nil
        retryCount = 0
    }
    private let formatter = { () -> ISO8601DateFormatter in
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private func refreshToken() async {
        fetchFailed = false
            do {
                var codexToken: (String, String)?
                if let localToken = localCodexToken {
                    codexToken = localToken
                } else {
                    codexToken = try await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
                }

                guard let codexToken = codexToken else {
                    throw NSError(domain: "CodexTokenManager", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to fetch codex token"
                    ])
                }

                // Create a configured ISO8601DateFormatter

                
                if let expiryDate = formatter.date(from: codexToken.1) {
                    let timeUntilExpiry = expiryDate.timeIntervalSinceNow
                    
                    // If expiry is less than 10 minutes away, throw an error
                    if timeUntilExpiry < 60 * 10 {
                        localCodexToken = nil
                        await self.refreshToken()
                        return
                    }
                    
                    // Set refresh timer to 5 minutes before expiration
                    refreshTimer?.invalidate()
                    let refreshTime = timeUntilExpiry - 5 // 5 minutes in seconds
                    refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: false) { [weak self] _ in
                        Task (priority: .high) {
                            await self?.refreshToken()
                        }
                    }
                }

                CodexNetwork.initialize(apiKey: codexToken.0)
                self.localCodexToken = codexToken
                self.retryCount = 0
                DispatchQueue.main.async {
                    self.isReady = true
                }

                
                
            } catch {
                if retryCount < maxRetryAttempts {
                    retryCount += 1
                    let delay = Double(retryCount) * 2 // Exponential backoff
                    Task (priority: .low) {
                        print("Fetch failed, retrying...")
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        await self.refreshToken()
                    }
                } else {
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
}
