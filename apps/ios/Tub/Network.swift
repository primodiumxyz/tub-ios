//
//  Network.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/2.
//

import Apollo
import ApolloWebSocket
import Foundation

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
        let httpURL = URL(string: "https://tub-graphql.primodium.ai/v1/graphql")!
        let store = ApolloStore()
        httpTransport = RequestChainNetworkTransport(
            interceptorProvider: DefaultInterceptorProvider(store: store),
            endpointURL: httpURL
        )

        let webSocketURL = URL(string: "wss://tub-graphql.primodium.ai/v1/graphql")!
        let websocket = WebSocket(url: webSocketURL, protocol: .graphql_ws)
        webSocketTransport = WebSocketTransport(websocket: websocket)
        
        // setup tRPC
        baseURL = URL(string: "http://localhost:8080/trpc")!
        session = URLSession(configuration: .default)
    }

    private func callProcedure<T: Codable>(_ procedure: String, input: Codable? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        var url = baseURL.appendingPathComponent(procedure)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
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
    func getStatus(completion: @escaping (Result<Status, Error>) -> Void) {
        callProcedure("getStatus", completion: completion)
    }
    
    func registerNewUser(username: String, airdropAmount: String? = nil, completion: @escaping (Result<UserResponse, Error>) -> Void) {
        let input = ["username": username, "airdropAmount": airdropAmount].compactMapValues { $0 }
        callProcedure("registerNewUser", input: input, completion: completion)
    }
    
    func incrementCall(completion: @escaping (Result<Increment, Error>) -> Void) {
        callProcedure("incrementCall", completion: completion)
    }

    func buyToken(accountId: String, tokenId: String, amount: String, completion: @escaping (Result<Transaction, Error>) -> Void) {
        let input = ["accountId": accountId, "tokenId": tokenId, "amount": amount]
        callProcedure("buyToken", input: input, completion: completion)
    }
    
    func sellToken(accountId: String, tokenId: String, amount: String, completion: @escaping (Result<Transaction, Error>) -> Void) {
        let input = ["accountId": accountId, "tokenId": tokenId, "amount": amount]
        callProcedure("sellToken", input: input, completion: completion)
    }
    
    func registerNewToken(name: String, symbol: String, supply: String? = nil, uri: String? = nil, completion: @escaping (Result<Token, Error>) -> Void) {
        let input = ["name": name, "symbol": symbol, "supply": supply, "uri": uri].compactMapValues { $0 }
        callProcedure("registerNewToken", input: input, completion: completion)
    }
    
    func airdropNativeToUser(accountId: String, amount: Double, completion: @escaping (Result<Transaction, Error>) -> Void) {
        let scaledAmount = String(Int(amount * 1e9))
        print(accountId, amount)
        let input = ["accountId": accountId, "amount": scaledAmount]
        callProcedure("airdropNativeToUser", input: input, completion: completion)
    }
}

// Add this new struct to handle the response wrapper
struct ResponseWrapper<T: Codable>: Codable {
    struct ResultWrapper: Codable {
        let data: T
    }
    let result: ResultWrapper
}


// Updated models:
struct Status: Codable {
}

struct Increment : Codable {
   
}

struct UserResponse: Codable {
    let id: String
    let __typename: String
}

struct Transaction: Codable {
}

struct Token: Codable {
}


