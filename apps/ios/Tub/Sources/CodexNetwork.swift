//
//  CodexNetwork.swift
//  Tub
//
//  Created by polarzero on 14/11/2024.
//

import Apollo
import ApolloWebSocket
import Foundation
import Security

// API key
public let apiKey: String = "0d0342ba23b7b3254589defd7abed9299d6adf36"

class CodexNetwork {
    static let shared = CodexNetwork()
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
    private let baseURL : URL
    private let session : URLSession
    
    init() {
        // setup graphql
        let httpURL = URL(string: "https://graph.codex.io/graphql")!
        let store = ApolloStore()
        httpTransport = RequestChainNetworkTransport(
            interceptorProvider: DefaultInterceptorProvider(store: store),
            endpointURL: httpURL,
            additionalHeaders: [
                "Authorization": apiKey,
                "Content-Type": "application/json"
            ]
        )
        
        let webSocketURL = URL(string: "wss://graph.codex.io/graphql")!
        let urlRequest = URLRequest(url: webSocketURL)
        let websocket = WebSocket(
            request: urlRequest,
            protocol: .graphql_transport_ws
        )

//        webSocketTransport = WebSocketTransport(websocket: websocket)
        webSocketTransport = {
            let authPayload = ["Authorization": apiKey]
          let config = WebSocketTransport.Configuration(connectingPayload: authPayload)
          return WebSocketTransport(websocket: websocket, config: config)
        }()
        
        // setup tRPC
        baseURL = URL(string: "https://graph.codex.io/graphql")!
        session = URLSession(configuration: .default)
    }
}
