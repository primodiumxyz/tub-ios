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

    private var refetchTimer: Timer?
    
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

    private func fetchToken () async throws -> (String, String) {
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
        return codexToken
    }
    private func refreshToken() async {
        fetchFailed = false
        do {
            var codexToken = try await fetchToken()

            if let expiryDate = formatter.date(from: codexToken.1) {
                let timeUntilExpiry = expiryDate.timeIntervalSinceNow
                
                if timeUntilExpiry < 60 * 6 {
                    localCodexToken = nil
                    codexToken = try await fetchToken()
                }
                
                // Schedule refresh at a specific time (5 minutes before expiration)
                refetchTimer?.invalidate()
                let refreshDate = expiryDate.addingTimeInterval(-5 * 60) // 5 minutes before expiry
                refetchTimer = Timer(fire: refreshDate, interval: 0, repeats: false) { [weak self] _ in
                    Task(priority: .high) {
                        guard let self else { return }
                        await self.refreshToken()
                    }
                }
                RunLoop.main.add(refetchTimer!, forMode: .common)
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
