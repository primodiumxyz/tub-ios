//
//  NetworkGraphQLExtension.swift
//  Tub
//
//  Created by polarzero on 07/01/2025.
//

import Apollo
import ApolloWebSocket
import Foundation

extension Network {
    // GraphQL configuration struct
    struct GraphQLConfig {
        static let defaultCacheTime = "30s"
        static let realtimeCacheTime = "5s"
        static let longCacheTime = "30m"
    }
    
    class GraphQLManager {
        private let httpTransport: RequestChainNetworkTransport
        private let webSocketTransport: WebSocketTransport
        
        private(set) lazy var client: ApolloClient = {
            let splitNetworkTransport = SplitNetworkTransport(
                uploadingNetworkTransport: httpTransport,
                webSocketNetworkTransport: webSocketTransport
            )
            
            let store = ApolloStore()
            return ApolloClient(networkTransport: splitNetworkTransport, store: store)
        }()
        
        init() {
            // Setup HTTP transport with Nginx caching headers
            let httpURL = URL(string: graphqlHttpUrl)!
            let store = ApolloStore()
            
            let requestBodyCreator = CachingRequestBodyCreator()
            
            httpTransport = RequestChainNetworkTransport(
                interceptorProvider: DefaultInterceptorProvider(store: store),
                endpointURL: httpURL,
                additionalHeaders: [:],
                requestBodyCreator: requestBodyCreator
            )
            
            // Setup WebSocket transport (unchanged)
            let webSocketURL = URL(string: graphqlWsUrl)!
            let websocket = WebSocket(url: webSocketURL, protocol: .graphql_ws)
            webSocketTransport = WebSocketTransport(websocket: websocket)
        }
        
        // Helper methods for different caching strategies
        func fetch<Query: GraphQLQuery>(
            query: Query,
            cachePolicy: CachePolicy = .default,
            cacheTime: String? = nil,
            bypassCache: Bool = false
        ) -> Promise<Query.Data> {
            var headers: [String: String] = [:]
            
            if bypassCache {
                headers["X-Cache-Bypass"] = "1"
            } else if let cacheTime = cacheTime {
                headers["X-Cache-Time"] = cacheTime
            }
            
            return client.fetch(
                query: query,
                cachePolicy: cachePolicy,
                context: RequestContext(headers: headers)
            )
        }
    }
}

// Custom RequestBodyCreator to handle caching headers
private class CachingRequestBodyCreator: RequestBodyCreator {
    func requestBody<Operation: GraphQLOperation>(
        for operation: Operation,
        sendQueryDocument: Bool,
        autoPersistQuery: Bool
    ) -> JSONEncodableDictionary {
        var body = super.requestBody(
            for: operation,
            sendQueryDocument: sendQueryDocument,
            autoPersistQuery: autoPersistQuery
        )
        
        // Add operation-specific cache hints
        if let cacheHint = operation.cacheHint {
            body["cacheHint"] = cacheHint
        }
        
        return body
    }
}