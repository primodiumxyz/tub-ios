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

    private func callProcedure<T: Codable, I: Codable>(
        _ procedure: String,
        input: I? = nil,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        Task {
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
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(input)
                    request.httpBody = data
                } catch {
                    completion(.failure(error))
                    return
                }
            }

            let task = session.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(
                        .failure(
                            NSError(
                                domain: "NetworkError", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }

                do {
                    // First, try to decode as an error response
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
                    {
                        let errorMessage = errorResponse.error.message
                        completion(
                            .failure(
                                NSError(
                                    domain: "ServerError", code: errorResponse.error.code ?? -1,
                                    userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                        return
                    }

                    // If it's not an error, proceed with normal decoding
                    let decodedResponse = try JSONDecoder().decode(
                        ResponseWrapper<T>.self, from: data)
                    completion(.success(decodedResponse.result.data))
                } catch {
                    completion(.failure(error))
                }
            }

            task.resume()
        }
    }

    private func callProcedure<T: Codable>(
        _ procedure: String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        callProcedure(procedure, input: Optional<EmptyInput>.none, completion: completion)
    }

    func getStatus(completion: @escaping (Result<StatusResponse, Error>) -> Void) {
        callProcedure<StatusResponse, EmptyInput>("getStatus", completion: completion)
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

    func buyToken(
        tokenId: String, amount: String, tokenPrice: String,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = TokenActionInput(tokenId: tokenId, amount: amount, tokenPrice: tokenPrice)
        callProcedure("buyToken", input: input, completion: completion)
    }

    func sellToken(
        tokenId: String, amount: String, tokenPrice: String,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = TokenActionInput(tokenId: tokenId, amount: amount, tokenPrice: tokenPrice)
        callProcedure("sellToken", input: input, completion: completion)
    }

    func airdropNativeToUser(
        amount: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = AirdropInput(amount: String(amount))
        callProcedure("airdropNativeToUser", input: input, completion: completion)
    }

    func recordClientEvent(
        event: ClientEvent, completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = EventInput(event: event)
        callProcedure("recordClientEvent", input: input, completion: completion)
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
                } else {
                    do {
                        print("Token expired, refreshing session")
                        let newSession = try await privy.refreshSession()
                        return newSession.authToken
                    } catch {
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

    private func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }

        let base64String = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padded = base64String.padding(
            toLength: ((base64String.count + 3) / 4) * 4,
            withPad: "=",
            startingAt: 0)

        guard let data = Data(base64Encoded: padded) else { return nil }

        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }

    func requestCodexToken(_ expiration: Int = 3600 * 1000) async throws -> String {
        let input: CodexTokenInput = .init(expiration: expiration)
        
        return try await withCheckedThrowingContinuation { continuation in
            callProcedure("requestCodexToken", input: input, completion: { (result: Result<CodexTokenResponse, Error>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

// MARK: - Response Types
struct ResponseWrapper<T: Codable>: Codable {
    struct ResultWrapper: Codable {
        let data: T
    }
    let result: ResultWrapper
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
        eventName: String, source: String, metadata: [[String: Any]]? = nil,
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
            } else {
                self.metadata = nil
            }
        } else {
            self.metadata = nil
        }

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            self.buildVersion = "\(version) (\(build))"
        } else {
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

// MARK: - Extensions
extension Network {
    func fetchSolPrice(completion: @escaping (Result<Double, Error>) -> Void) {
        let url = URL(string: "https://min-api.cryptocompare.com/data/price?fsym=SOL&tsyms=USD")!
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(
                    .failure(
                        NSError(
                            domain: "NetworkError", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: [])
                    as? [String: Double],
                    let price = json["USD"]
                {
                    completion(.success(price))
                } else {
                    completion(
                        .failure(
                            NSError(
                                domain: "ParsingError", code: 0,
                                userInfo: [
                                    NSLocalizedDescriptionKey: "Failed to parse JSON response"
                                ])))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

private struct CodexTokenResponse: Codable {
    let token: String
}
