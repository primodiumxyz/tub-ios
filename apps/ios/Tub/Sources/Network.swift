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

class Network {
    static let shared = Network()
    
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
    private let baseURL : URL 
    private let session : URLSession
    
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

    private func callProcedure<T: Codable>(_ procedure: String, input: Codable? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        let url = baseURL.appendingPathComponent(procedure)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add JWT token to the header

        if let token = getStoredToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let input = input {
            do {
                request.httpBody = try JSONEncoder().encode(input)
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
                completion(.failure(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // First, try to decode as an error response
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    let errorMessage = errorResponse.error.message
                    completion(.failure(NSError(domain: "ServerError", code: errorResponse.error.code ?? -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    return
                }
                
                // If it's not an error, proceed with normal decoding
                let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
                completion(.success(decodedResponse.result.data))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Updated procedure calls:
    func getStatus(completion: @escaping (Result<StatusResponse, Error>) -> Void) {
        callProcedure("getStatus", completion: completion)
    }
    
    @available(*, deprecated)
    func registerNewUser(username: String, airdropAmount: String? = nil, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        let input = ["username": username, "airdropAmount": airdropAmount].compactMapValues { $0 }
        callProcedure("registerNewUser", input: input) { (result: Result<UserResponse, Error>) in
            switch result {
            case .success(let userResponse):
                self.storeToken(userResponse.token)
                completion(.success(userResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func storeToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    @available(*, deprecated)
    func incrementCall(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        callProcedure("incrementCall", completion: completion)
    }

    func buyToken(tokenId: String, amount: String, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["tokenId": tokenId, "amount": amount]
        callProcedure("buyToken", input: input, completion: completion)
    }
    
    func sellToken(tokenId: String, amount: String, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["tokenId": tokenId, "amount": amount]
        callProcedure("sellToken", input: input, completion: completion)
    }
    
    func registerNewToken(name: String, symbol: String, supply: String? = nil, uri: String? = nil, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["name": name, "symbol": symbol, "supply": supply, "uri": uri].compactMapValues { $0 }
        callProcedure("registerNewToken", input: input, completion: completion)
    }
    
    func airdropNativeToUser(amount: Int, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["amount": String(amount)]
        callProcedure("airdropNativeToUser", input: input, completion: completion)
    }
    
    func getCoinbaseSolanaOnrampUrl(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["accountId": accountId]
        callProcedure("getCoinbaseSolanaOnrampUrl", completion: completion)
    }
}

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


extension Network {
    func getStoredToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "userToken",
            kSecReturnData as String: true
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }

    func fetchSolPrice(completion: @escaping (Result<Double, Error>) -> Void) {
        let url = URL(string: "https://min-api.cryptocompare.com/data/price?fsym=SOL&tsyms=Usd")!
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Double],
                   let price = json["USD"] {
                    completion(.success(price))
                } else {
                    completion(.failure(NSError(domain: "ParsingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
