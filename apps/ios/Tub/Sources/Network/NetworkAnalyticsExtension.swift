//
//  NetworkAnalyticsExtension.swift
//  Tub
//
//  Created by Henry on 12/12/24.
//
import UIKit

extension Network {
struct EventInput: Codable {
    let userAgent: String
    let buildVersion: String?
    let errorDetails: String?
    let eventName: String
    let source: String
    let metadata: String?  // Keep as string internally

    init(event: ClientEvent) {
        let device = UIDevice.current
        let userAgent = "\(device.systemName) \(device.systemVersion) \(device.name)"

        self.userAgent = userAgent
        self.source = event.source
        self.eventName = event.eventName
        self.errorDetails = event.errorDetails

        // Merge all metadata dictionaries into one
        if let metadata = event.metadata {
            var mergedMetadata: [String: Any] = [:]
            for dict in metadata {
                mergedMetadata.merge(dict) { current, _ in current }
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: mergedMetadata),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                self.metadata = jsonString
            }
            else {
                self.metadata = nil
            }
        }
        else {
            self.metadata = nil
        }

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            self.buildVersion = "\(version) (\(build))"
        }
        else {
            self.buildVersion = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userAgent, forKey: .userAgent)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(source, forKey: .source)
        if let errorDetails = errorDetails {
            try container.encode(errorDetails, forKey: .errorDetails)
        }
        if let buildVersion = buildVersion {
            try container.encode(buildVersion, forKey: .buildVersion)
        }
        if let metadata = metadata {
            try container.encode(metadata, forKey: .metadata)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case userAgent
        case eventName
        case errorDetails
        case source
        case buildVersion
        case metadata
    }
}
struct ClientEvent {
    let eventName: String
    let source: String
    var errorDetails: String? = nil
    var metadata: [[String: Any]]? = nil

    init(
        eventName: String,
        source: String,
        metadata: [[String: Any]]? = nil,
        errorDetails: String? = nil
    ) {
        self.eventName = eventName
        self.source = source
        self.metadata = metadata
        self.errorDetails = errorDetails
    }
}

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
            userWallet: await getStoredToken()
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
            userWallet: await getStoredToken()
        )
        
        let _: EmptyResponse = try await callMutation("recordTokenSale", input: input)
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
