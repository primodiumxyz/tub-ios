//
//  Network.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/2.
//

import Apollo
import ApolloWebSocket
import Foundation
import Security
import UIKit

class Network {
    static let shared = Network()
    private var lastApiCallTime: Date = Date()

    // graphql
    private let httpTransport: RequestChainNetworkTransport
    private let webSocketTransport: WebSocketTransport

    private(set) lazy var apollo: ApolloClient = {
        let splitNetworkTransport = SplitNetworkTransport(
            uploadingNetworkTransport: httpTransport,
            webSocketNetworkTransport: webSocketTransport
        )

        let store = ApolloStore()
        return ApolloClient(networkTransport: splitNetworkTransport, store: store)
    }()

    // tRPC
    private let baseURL: URL
    private let session: URLSession

    init() {
        // setup graphql
        let httpURL = URL(string: graphqlHttpUrl)!
        let store = ApolloStore()
        httpTransport = RequestChainNetworkTransport(
            interceptorProvider: DefaultInterceptorProvider(store: store),
            endpointURL: httpURL
        )

        let webSocketURL = URL(string: graphqlWsUrl)!
        let websocket = WebSocket(url: webSocketURL, protocol: .graphql_ws)
        webSocketTransport = WebSocketTransport(websocket: websocket)

        // setup tRPC
        baseURL = URL(string: serverBaseUrl)!
        session = URLSession(configuration: .default)
    }

    // MARK: - Calls
    func getStatus() async throws -> Int {
        let response: StatusResponse = try await callProcedure("getStatus")
        return response.status
    }

    func buyToken(tokenId: String, amount: String, tokenPrice: String) async throws {
        let input = TokenActionInput(tokenId: tokenId, amount: amount, tokenPrice: tokenPrice)
        let _: EmptyResponse = try await callProcedure("buyToken", input: input)
    }

    func sellToken(tokenId: String, amount: String, tokenPrice: String) async throws {
        let input = TokenActionInput(tokenId: tokenId, amount: amount, tokenPrice: tokenPrice)
        let _: EmptyResponse = try await callProcedure("sellToken", input: input)
    }

    func airdropNativeToUser(amount: Int) async throws {
        let input = AirdropInput(amount: String(amount))
        let _: EmptyResponse = try await callProcedure("airdropNativeToUser", input: input)
    }

    func recordClientEvent(event: ClientEvent) async throws {
        let input = EventInput(event: event)
        let _: EmptyResponse = try await callProcedure("recordClientEvent", input: input)
    }

    // MARK: - Call Procedure
    private func callProcedure<T: Codable, I: Codable>(
        _ procedure: String,
        input: I? = nil
    ) async throws -> T {
        // Get token asynchronously
        let token = await getStoredToken()

        let url = baseURL.appendingPathComponent(procedure)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let input = input {
            let encoder = JSONEncoder()
            let data = try encoder.encode(input)
            request.httpBody = data
        }

        let (data, _) = try await session.data(for: request)

        // First, try to decode as an error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            print(errorResponse)
            throw TubError.parsingError
        }

        // If it's not an error, proceed with normal decoding
        let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
        return decodedResponse.result.data
    }

    private func callProcedure<T: Codable>(_ procedure: String) async throws -> T {
        return try await callProcedure(procedure, input: Optional<EmptyInput>.none)
    }
    // MARK: - JWT

    private func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }

        let base64String = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padded = base64String.padding(
            toLength: ((base64String.count + 3) / 4) * 4,
            withPad: "=",
            startingAt: 0
        )

        guard let data = Data(base64Encoded: padded) else { return nil }

        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }

    private func storeToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func getStoredToken() async -> String? {
        switch privy.authState {
        case .authenticated(let authSession):
            let token = authSession.authToken
            // Check if token is expired
            if let decodedToken = decodeJWT(token),
                let exp = decodedToken["exp"] as? TimeInterval
            {
                let expirationDate = Date(timeIntervalSince1970: exp)
                if expirationDate > Date() {
                    return token
                }
                else {
                    do {
                        print("Token expired, refreshing session")
                        let newSession = try await privy.refreshSession()
                        return newSession.authToken
                    }
                    catch {
                        print("Failed to refresh session: \(error)")
                        return nil
                    }
                }
            }
            return nil
        default:
            return nil
        }
    }

    func getSolPrice() async throws -> Double {
        let url = baseURL.appendingPathComponent("getSolUsdPrice")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await session.data(for: request)
        
        // First, try to decode as an error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            print(errorResponse)
            throw TubError.networkFailure
        }
        
        // If it's not an error, proceed with normal decoding
        let response = try JSONDecoder().decode(ResponseWrapper<Double>.self, from: data)
        return response.result.data
    }
}

// MARK: - Response Types
struct ResponseWrapper<T: Codable>: Codable {
    struct ResultWrapper: Codable {
        let data: T
    }
    let result: ResultWrapper
}

private struct ErrorResponse: Codable {
    let error: ErrorDetails

    struct ErrorDetails: Codable {
        let message: String
        let code: Int?
        let data: ErrorData?
    }

    struct ErrorData: Codable {
        let code: String?
        let httpStatus: Int?
        let stack: String?
        let path: String?
    }
}

struct CodexTokenResponse: Codable {
    let token: String
    let expiry: String
}

struct EmptyResponse: Codable {}

struct UserResponse: Codable {
    let uuid: String
    let token: String
}

struct RefreshTokenResponse: Codable {
    let token: String
}

struct StatusResponse: Codable {
    let status: Int
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

// MARK: - Input Types
struct RegisterUserInput: Codable {
    let username: String
    let airdropAmount: String?
}

struct TokenActionInput: Codable {
    // Wrap in a dictionary structure that matches server expectation
    private enum CodingKeys: String, CodingKey {
        case tokenId, amount, tokenPrice
    }

    let tokenId: String
    let amount: String
    let tokenPrice: String
}

struct RegisterTokenInput: Codable {
    let name: String
    let symbol: String
    let supply: String?
    let uri: String?
}

struct AirdropInput: Codable {
    let amount: String
}

struct CodexTokenInput: Codable {
    let expiration: Int
}

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

private struct EmptyInput: Codable {}
