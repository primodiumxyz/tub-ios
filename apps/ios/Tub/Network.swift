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

    // tRPC
    private let baseURL : URL 
    private let session : URLSession
    
    init() {
        // setup graphql
        let httpURL = URL(string: "http://localhost:8080/v1/graphql")!
        let store = ApolloStore()
        httpTransport = RequestChainNetworkTransport(
            interceptorProvider: DefaultInterceptorProvider(store: store),
            endpointURL: httpURL
        )

        let webSocketURL = URL(string: "wss://localhost:8080/v1/graphql")!
        let websocket = WebSocket(url: webSocketURL, protocol: .graphql_ws)
        webSocketTransport = WebSocketTransport(websocket: websocket)
        
        // setup tRPC
        baseURL = URL(string: "http://localhost:8888/trpc")!
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
            
            // Print the response as a string
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response for \(procedure):")
                print(responseString)
            } else {
                print("Unable to convert response data to string for \(procedure)")
            }
            
            do {
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
    
    func registerNewUser(username: String, airdropAmount: String? = nil, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        let input = ["username": username, "airdropAmount": airdropAmount].compactMapValues { $0 }
        callProcedure("registerNewUser", input: input) { (result: Result<UserResponse, Error>) in
            switch result {
            case .success(let userResponse):
                print(userResponse)
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

    func incrementCall(completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        callProcedure("incrementCall", completion: completion)
    }

    func buyToken(accountId: String, tokenId: String, amount: String, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["accountId": accountId, "tokenId": tokenId, "amount": amount]
        callProcedure("buyToken", input: input, completion: completion)
    }
    
    func sellToken(accountId: String, tokenId: String, amount: String, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["accountId": accountId, "tokenId": tokenId, "amount": amount]
        callProcedure("sellToken", input: input, completion: completion)
    }
    
    func registerNewToken(name: String, symbol: String, supply: String? = nil, uri: String? = nil, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let input = ["name": name, "symbol": symbol, "supply": supply, "uri": uri].compactMapValues { $0 }
        callProcedure("registerNewToken", input: input, completion: completion)
    }
    
    func airdropNativeToUser(accountId: String, amount: Double, completion: @escaping (Result<EmptyResponse, Error>) -> Void) {
        let scaledAmount = String(Int(amount * 1e9))
        print(accountId, amount)
        let input = ["accountId": accountId, "amount": scaledAmount]
        callProcedure("airdropNativeToUser", input: input, completion: completion)
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
        
        print(token)
        return token
    }

    func refreshToken(completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentToken = getStoredToken() else {
            completion(.failure(NSError(domain: "TokenRefresh", code: 0, userInfo: [NSLocalizedDescriptionKey: "No token stored"])))
            return
        }
        
        callProcedure("refreshToken", input: ["token": currentToken]) { (result: Result<RefreshTokenResponse, Error>) in
            switch result {
            case .success(let response):
                self.storeToken(response.token)
                completion(.success(response.token))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

