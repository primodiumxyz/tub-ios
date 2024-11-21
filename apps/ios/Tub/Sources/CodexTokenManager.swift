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

  var value: (String, String) {
    (token, expiry)
  }

  init(token: String, expiry: String) {
    self.token = token
    self.expiry = expiry
  }
}

class CodexTokenManager: ObservableObject {
  static let shared = CodexTokenManager()

  private let tokenExpiration: TimeInterval = 60 * 60  // 1h
  private let maxRetryAttempts = 2
  private var retryCount = 0
  @Published var fetchFailed = false
  @Published var isReady = false
  @AppStorage("codexToken") private var localCodexToken: CodexTokenData?

  private var refetchTimer: Timer?
  private var isRefreshing = false

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

  private func fetchToken(hard: Bool? = false) async throws -> CodexTokenData {
    var codexToken: CodexTokenData?
    if let localToken = localCodexToken, hard != true {
      codexToken = localToken
    } else {
      do {
        print("fetching new token...")
        codexToken = try await Network.shared.requestCodexToken(Int(tokenExpiration) * 1000)
      } catch {
        print(error)
        throw error
      }
    }
    guard let codexToken = codexToken else {
      throw TubError.networkFailure
    }
    print("codexToken: \(codexToken.token)")
    return codexToken
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
      var codexToken = try await fetchToken(hard: hard)

      if let expiryDate = formatter.date(from: codexToken.expiry) {
        let timeUntilExpiry = expiryDate.timeIntervalSinceNow
        print(
          "time until expiry: \(timeUntilExpiry), codexToken.expiry: \(codexToken.expiry), now: \(Date())"
        )

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
              repeats: false)
            RunLoop.main.add(refetchTimer!, forMode: .common)
          }
        } else {
          // If we're too close to expiry or past it, refresh immediately

          localCodexToken = nil
          codexToken = try await fetchToken(hard: true)
        }
      }

      CodexNetwork.initialize(apiKey: codexToken.token)
      self.localCodexToken = CodexTokenData(token: codexToken.token, expiry: codexToken.expiry)
      await MainActor.run {
        self.retryCount = 0
        self.isReady = true
      }

    } catch {
      if retryCount < maxRetryAttempts {
        retryCount += 1
        let delay = Double(retryCount) * 2  // Exponential backoff
        Task(priority: .low) {
          print("Fetch failed, retrying...")
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          await self.refreshToken(hard: true)
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

  @objc private func refreshTokenTimerFired() {
    Task { await refreshToken() }
  }
}
