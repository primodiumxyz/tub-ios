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

/**
 * This extension adds GraphQL-related functions to the Network class.
 * It will handle the fetching and subscribing to GraphQL queries and subscriptions.
 * It will also handle the caching of GraphQL queries (passing cache headers to the server).
*/
extension Network {
    // GraphQL configuration struct
    struct GraphQLConfig {
        static let defaultCacheTime = "30s"
    }
    
    class GraphQLManager {
        private let store: ApolloStore = ApolloStore()
        private let interceptorProvider: DynamicInterceptorProvider
        private let httpTransport: RequestChainNetworkTransport
        private let webSocketTransport: WebSocketTransport
        
        private(set) lazy var client: ApolloClient = {
            let splitNetworkTransport = SplitNetworkTransport(
                uploadingNetworkTransport: httpTransport,
                webSocketNetworkTransport: webSocketTransport
            )
            return ApolloClient(networkTransport: splitNetworkTransport, store: ApolloStore())
        }()
        
        // Custom interceptor to handle cache headers
        private class CacheHeadersInterceptor: ApolloInterceptor {
            let id = "CacheHeadersInterceptor"
            let cacheTime: String?
            let bypassCache: Bool
            
            init(cacheTime: String?, bypassCache: Bool) {
                self.cacheTime = cacheTime
                self.bypassCache = bypassCache
            }
            
            func interceptAsync<Operation: GraphQLOperation>(
                chain: RequestChain,
                request: HTTPRequest<Operation>,
                response: HTTPResponse<Operation>?,
                completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
            ) {
                request.addHeader(name: "x-cache-time", value: cacheTime ?? GraphQLConfig.defaultCacheTime)
                request.addHeader(name: "x-cache-bypass", value: bypassCache ? "1" : "0")
                
                chain.proceedAsync(
                    request: request,
                    response: response,
                    completion: completion
                )
            }
        }
        
        // Custom interceptor provider that can handle dynamic interceptors
        private class DynamicInterceptorProvider: DefaultInterceptorProvider {
            private var cacheInterceptor: CacheHeadersInterceptor?
            
            func set(_ interceptor: CacheHeadersInterceptor) {
                self.cacheInterceptor = interceptor
            }
            
            override func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
                var interceptors = super.interceptors(for: operation)
                if let cacheInterceptor = cacheInterceptor {
                    interceptors.insert(cacheInterceptor, at: 0)
                }
                return interceptors
            }
        }
        
        init() {
            let httpURL = URL(string: graphqlHttpUrl)!
            
            // Setup interceptor provider
            interceptorProvider = DynamicInterceptorProvider(store: store)
            
            // Setup HTTP transport
            httpTransport = RequestChainNetworkTransport(
                interceptorProvider: interceptorProvider,
                endpointURL: httpURL
            )
            
            // Setup WebSocket transport
            let webSocketURL = URL(string: graphqlWsUrl)!
            let websocket = WebSocket(url: webSocketURL, protocol: .graphql_ws)
            webSocketTransport = WebSocketTransport(websocket: websocket)
        }
        
        func fetch<Query: GraphQLQuery>(
            query: Query,
            cachePolicy: CachePolicy = .default,
            cacheTime: Interval? = nil,
            bypassCache: Bool = false,
            completion: @escaping (Result<GraphQLResult<Query.Data>, Error>) -> Void
        ) {
            let cacheInterceptor = CacheHeadersInterceptor(
                cacheTime: cacheTime ?? GraphQLConfig.defaultCacheTime,
                bypassCache: bypassCache
            )
            interceptorProvider.set(cacheInterceptor)
            
            client.fetch(
                query: query,
                cachePolicy: cachePolicy,
                queue: .main
            ) { result in
                completion(result)
            }
        }
        
        func subscribe<Subscription: GraphQLSubscription>(
            subscription: Subscription,
            completion: @escaping (Result<GraphQLResult<Subscription.Data>, Error>) -> Void
        ) -> Cancellable {
            return client.subscribe(subscription: subscription) { result in
                completion(result)
            }
        }
    }
}
