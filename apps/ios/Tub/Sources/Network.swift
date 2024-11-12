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

    // privy sessions last one hour so we refresh session after 45 minutes to be safe
    // https://docs.privy.io/guide/security/#refresh-token
    private let sessionTimeout: TimeInterval = 60 * 45  // 45 minutes in seconds

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
            if Date().timeIntervalSince(lastApiCallTime) > sessionTimeout {
                do {
                    _ = try await privy.refreshSession()
                } catch {
                    completion(.failure(error))
                    return
                }

                self.lastApiCallTime = Date()
            }

            let url = baseURL.appendingPathComponent(procedure)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            if let token = getStoredToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            if let input = input {
                do {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(input)
                    request.httpBody = data

                    // Debug print the actual JSON being sent
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Sending JSON for \(procedure): \(jsonString)")
                    }
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
        tokenId: String, amount: String,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = TokenActionInput(tokenId: tokenId, amount: amount)
        callProcedure("buyToken", input: input, completion: completion)
    }

    func sellToken(
        tokenId: String, amount: String,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = TokenActionInput(tokenId: tokenId, amount: amount)
        callProcedure("sellToken", input: input, completion: completion)
    }

    func registerNewToken(
        name: String, symbol: String, supply: String? = nil, uri: String? = nil,
        completion: @escaping (Result<EmptyResponse, Error>) -> Void
    ) {
        let input = RegisterTokenInput(name: name, symbol: symbol, supply: supply, uri: uri)
        callProcedure("registerNewToken", input: input, completion: completion)
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
        case tokenId, amount
    }

    let tokenId: String
    let amount: String
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

struct EventInput: Codable {
    let userAgent: String
    let buildVersion: String?
    let errorDetails: String?
    let eventName: String
    let source: String
    let metadata: String?  // JSON string

    init(event: ClientEvent) {
        let device = UIDevice.current
        let userAgent = "\(device.systemName)-\(device.systemVersion)-\(device.name)"

        self.userAgent = userAgent
        self.source = event.source
        self.eventName = event.eventName
        self.errorDetails = event.errorDetails

        // Convert metadata - take first item from array if it exists
        if let metadata = event.metadata?.first,  // Get first item from array
            let jsonData = try? JSONSerialization.data(withJSONObject: metadata),
            let jsonString = String(data: jsonData, encoding: .utf8)
        {
            self.metadata = jsonString
        } else {
            self.metadata = nil
        }

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.buildVersion = version
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
    func getStoredToken() -> String? {
        switch privy.authState {
        case .authenticated(let authSession):
            return authSession.authToken
        default:
            return nil
        }
    }

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
