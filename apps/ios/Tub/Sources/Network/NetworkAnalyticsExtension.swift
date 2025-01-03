//
//  NetworkAnalyticsExtension.swift
//  Tub
//
//  Created by Henry on 12/12/24.
//
import UIKit

extension Network {
    func recordTokenPurchase(
        tokenMint: String,
        tokenAmount: Double,
        tokenPriceUsd: Double,
        source: String,
        errorDetails: String? = nil
    ) async throws {
        let metadata = getClientMetadata()
        let input = TokenPurchaseInput(
            tokenMint: tokenMint,
            tokenAmount: String(tokenAmount),
            tokenPriceUsd: String(tokenPriceUsd),
            source: source,
            errorDetails: errorDetails,
            userAgent: metadata["userAgent"] ?? "unknown",
            buildVersion: metadata["buildVersion"] ?? "unknown",
            userWallet: await getStoredToken() ?? ""
        )
        
        let _: EmptyResponse = try await callMutation("recordTokenPurchase", input: input)
    }

    func recordTokenSale(
        tokenMint: String,
        tokenAmount: Double,
        tokenPriceUsd: Double,
        source: String,
        errorDetails: String? = nil
    ) async throws {
        let metadata = getClientMetadata()
        let input = TokenSaleInput(
            tokenMint: tokenMint,
            tokenAmount: String(tokenAmount),
            tokenPriceUsd: String(tokenPriceUsd),
            source: source,
            errorDetails: errorDetails,
            userAgent: metadata["userAgent"] ?? "unknown",
            buildVersion: metadata["buildVersion"] ?? "unknown",
            userWallet: await getStoredToken() ?? ""
        )
        
        let _: EmptyResponse = try await callMutation("recordTokenSale", input: input)
    }

    func recordLoadingTime(
        identifier: String,
        timeElapsedMs: Int,
        attemptNumber: Int,
        totalTimeMs: Int,
        averageTimeMs: Int,
        source: String,
        errorDetails: String? = nil
    ) async throws {
        let metadata = getClientMetadata()
        let input = LoadingTimeInput(
            identifier: identifier,
            timeElapsedMs: timeElapsedMs,
            attemptNumber: attemptNumber,
            totalTimeMs: totalTimeMs,
            averageTimeMs: averageTimeMs,
            source: source,
            errorDetails: errorDetails,
            userAgent: metadata["userAgent"] ?? "unknown",
            buildVersion: metadata["buildVersion"] ?? "unknown",
            userWallet: await getStoredToken() ?? ""
        )

        let _: EmptyResponse = try await callMutation("recordLoadingTime", input: input)
    }

    func recordAppDwellTime(
        dwellTimeMs: Int,
        source: String,
        errorDetails: String? = nil
    ) async throws {
        let metadata = getClientMetadata()
        let input = AppDwellTimeInput(
            dwellTimeMs: dwellTimeMs,
            source: source,
            errorDetails: errorDetails,
            userAgent: metadata["userAgent"] ?? "unknown",
            buildVersion: metadata["buildVersion"] ?? "unknown",
            userWallet: await getStoredToken() ?? ""
        )

        let _: EmptyResponse = try await callMutation("recordAppDwellTime", input: input)
    }

    func recordTokenDwellTime(
        tokenMint: String,
        dwellTimeMs: Int,
        source: String,
        errorDetails: String? = nil
    ) async throws {
        let metadata = getClientMetadata()
        let input = TokenDwellTimeInput(
            tokenMint: tokenMint,
            dwellTimeMs: dwellTimeMs,
            source: source,
            errorDetails: errorDetails,
            userAgent: metadata["userAgent"] ?? "unknown",
            buildVersion: metadata["buildVersion"] ?? "unknown",
            userWallet: await getStoredToken() ?? ""
        )

        let _: EmptyResponse = try await callMutation("recordTokenDwellTime", input: input)
    }

    private func getClientMetadata() -> [String: String] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let buildVersion = "\(version)(\(build))"
        let userAgent = "iOS/\(UIDevice.current.systemVersion)"
        
        return [
            "buildVersion": buildVersion,
            "userAgent": userAgent
        ]
    }
}
