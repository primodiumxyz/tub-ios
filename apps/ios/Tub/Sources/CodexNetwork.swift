//
//  CodexNetwork.swift
//  Tub
//
//  Created by polarzero on 14/11/2024.
//

import Apollo
import Foundation

class CodexNetwork {
    static let shared = CodexNetwork()
    
    private let apiKey: String
    
    private(set) lazy var apollo: ApolloClient = {
        let store = ApolloStore()
        
        let interceptorProvider = DefaultInterceptorProvider(store: store)
        
        // Create custom interceptor chain to add API key
        let interceptor = RequestChainNetworkTransport(
            interceptorProvider: interceptorProvider,
            endpointURL: URL(string: "https://graph.codex.io/graphql")!,
            additionalHeaders: [
                "Authorization": "API_KEY",
                "Content-Type": "application/json"
            ]
        )
        
        return ApolloClient(networkTransport: interceptor, store: store)
    }()
    
    init() {
        // In production, load from secure storage/environment
        self.apiKey = "<MY_KEY>"
    }
}
