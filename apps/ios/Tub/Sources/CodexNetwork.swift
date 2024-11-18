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

class CodexNetwork {
    // Static instance
    private static var _shared = CodexNetwork()
    static var shared: CodexNetwork { _shared }
    
    // Initialization state
    private var initializationContinuation: CheckedContinuation<Void, Never>?
    private var isInitialized = false
    private let initializationLock = NSLock()
    
    // Instance properties
    private var apiKey: String?
    private var lastApiCallTime: Date = Date()
    
    // graphql
    private var httpTransport: RequestChainNetworkTransport?
    private var webSocketTransport: WebSocketTransport?
    
    private(set) lazy var apollo: ApolloClient = {
        guard let httpTransport = httpTransport,
              let webSocketTransport = webSocketTransport else {
            fatalError("Attempted to access Apollo client before initialization")
        }
        
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
    private var baseURL: URL
    private var session: URLSession
    
    private init() {
        // Initialize with dummy values that will be replaced
        self.baseURL = URL(string: "https://dummy.url")!
        self.session = URLSession(configuration: .default)
    }
    
    static func initialize(apiKey: String) {
        shared.setup(with: apiKey)
    }
    
    private func setup(with apiKey: String) {
        initializationLock.lock()
        defer { initializationLock.unlock() }
        
        self.apiKey = apiKey
        
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

         webSocketTransport = {
          let authPayload = ["Authorization": apiKey]
          let config = WebSocketTransport.Configuration(connectingPayload: authPayload)
          return WebSocketTransport(websocket: websocket, config: config)
        }()
        
        // setup tRPC
        self.baseURL = URL(string: "https://graph.codex.io/graphql")!
        self.session = URLSession(configuration: .default)
        
        isInitialized = true
        
        // Resume any waiting operations
        initializationContinuation?.resume()
        initializationContinuation = nil
    }
    
    private func waitForInitialization() async {
        guard !isInitialized else { return }
        
        await withCheckedContinuation { continuation in
            initializationLock.lock()
            if isInitialized {
                initializationLock.unlock()
                continuation.resume()
                return
            }
            
            initializationContinuation = continuation
            initializationLock.unlock()
        }
    }
    
    // Apollo client accessor
    var apolloClient: ApolloClient {
        get async {
            await waitForInitialization()
            return apollo
        }
    }
}
