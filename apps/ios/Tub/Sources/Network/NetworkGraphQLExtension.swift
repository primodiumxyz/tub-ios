//
//  NetworkGraphQLExtension.swift
//  Tub
//
//  Created by polarzero on 07/01/2025.
//

import Apollo
import ApolloAPI
import ApolloWebSocket
import Foundation
import TubAPI

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
            
            httpTransport = RequestChainNetworkTransport(
                interceptorProvider: DefaultInterceptorProvider(store: store),
                endpointURL: httpURL,
                additionalHeaders: [:]
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
            cacheTime: Interval? = nil,
            bypassCache: Bool = false,
            completion: @escaping (Result<GraphQLResult<Query.Data>, Error>) -> Void
        ) {
            var headers: [String: String] = [:]
            
            if bypassCache {
                headers["X-Cache-Bypass"] = "1"
            } else if let cacheTime = cacheTime {
                headers["X-Cache-Time"] = cacheTime
            }
            
            client.fetch(
                query: query,
                cachePolicy: cachePolicy,
                context: ["headers": headers] as [String: Any] as? RequestContext
            ) { result in
                completion(result)
            }
        }
        
        func subscribe<Subscription: GraphQLSubscription>(
            subscription: Subscription,
            completion: @escaping (Result<GraphQLResult<Subscription.Data>, Error>) -> Void
        ) -> Cancellable {
            return client.subscribe(
                subscription: subscription
            ) { result in
                completion(result)
            }
        }
    }
}
