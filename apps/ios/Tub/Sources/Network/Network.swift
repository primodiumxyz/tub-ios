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
    
    // MARK: - API 

    func callMutation<T: Codable, I: Codable>(
        _ mutation: String,
        input: I? = nil,
        tokenRequired: Bool = false
    ) async throws -> T {
        // Get token asynchronously
        let token = await getStoredToken()
        
        let url = baseURL.appendingPathComponent(mutation)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if tokenRequired {
            throw TubError.somethingWentWrong(reason: "JWT token required")
        }
        
        if let input = input {
            let encoder = JSONEncoder()
            let data = try encoder.encode(input)
            request.httpBody = data
        }
        
        let (data, _) = try await session.data(for: request)
        
        // First, try to decode as an error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            print("Error: \(errorResponse.error.message)")
            throw TubError.serverError(reason: errorResponse.error.message)
        }
        
        // If it's not an error, proceed with normal decoding
        do {
            let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
            return decodedResponse.result.data
        } catch {
            throw TubError.parsingError
        }
    }
    
    func callMutation<T: Codable>(_ mutation: String, tokenRequired: Bool = false) async throws -> T {
        return try await callMutation(mutation, input: Optional<EmptyInput>.none, tokenRequired: tokenRequired)
    }

    func callQuery<T: Codable, I: Codable>(
        _ query: String,
        input: I? = nil,
        tokenRequired: Bool = false
    ) async throws -> T {
        let token = await getStoredToken()
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(query), resolvingAgainstBaseURL: true)!
        if let input = input {
            let encoder = JSONEncoder()
            let data = try encoder.encode(input)
            if let jsonString = String(data: data, encoding: .utf8) {
                urlComponents.queryItems = [URLQueryItem(name: "input", value: jsonString)]
            }
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if tokenRequired {
            throw TubError.somethingWentWrong(reason: "JWT token required")
        }
        
        let (data, _) = try await session.data(for: request)
        
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            print("Error: \(errorResponse.error.message)")
            throw TubError.serverError(reason: errorResponse.error.message)
        }
        
        let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
        return decodedResponse.result.data
    }
    
    private func callQuery<T: Codable>(_ query: String, tokenRequired: Bool = false) async throws -> T {
        return try await callQuery(query, input: Optional<EmptyInput>.none, tokenRequired: tokenRequired)
    }
    
    
    // MARK: - JWT
    
    private func decodeJWT(_ token: String) -> [String: Any]? {
        let segments = token.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        let base64String = segments[1]
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let padded = base64String.padding(
            toLength: ((base64String.count + 3) / 4) * 4,
            withPad: "=",
            startingAt: 0
        )
        
        guard let data = Data(base64Encoded: padded) else { return nil }
        
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
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
    
    func getStoredToken(hardRefresh: Bool? = false) async -> String? {
        switch privy.authState {
        case .authenticated(let authSession):
            let token = authSession.authToken
            // Check if token is expired
            if let decodedToken = decodeJWT(token),
               let exp = decodedToken["exp"] as? TimeInterval
            {
                let expirationDate = Date(timeIntervalSince1970: exp)
                if expirationDate > Date() && hardRefresh != true {
                    return token
                } else {
                    do {
                        print("Token expired, refreshing session")
                        let newSession = try await privy.refreshSession()
                        return newSession.authToken
                    } catch {
                        print("Failed to refresh session: \(error)")
                        return nil
                    }
                }
            }
            return nil
        default:
            return nil
        }
    }

    // MARK - Calls

   func getStatus() async throws -> Int {
        let response: StatusResponse = try await callQuery("getStatus")
        return response.status
    }
    
    func recordClientEvent(event: ClientEvent) async throws {
        let input = EventInput(event: event)
        let _: EmptyResponse = try await callMutation("recordClientEvent", input: input)
    }
    
    func getSolPrice() async throws -> Double {
        let url = baseURL.appendingPathComponent("getSolUsdPrice")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, _) = try await session.data(for: request)
        
        // First, try to decode as an error response
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            print(errorResponse)
            throw TubError.networkFailure
        }
        
        // If it's not an error, proceed with normal decoding
        let response = try JSONDecoder().decode(ResponseWrapper<Double>.self, from: data)
        return response.result.data
    }
    
    func getBalance() async throws -> Int {
        let res: BalanceResponse = try await callQuery("getBalance", tokenRequired: true)
        return res.balance
    }
    
    func getAllTokenBalances() async throws -> [String : Int] {
        let res: BulkTokenBalanceResponse = try await callQuery("getAllTokenBalances", tokenRequired: true)
        return res.tokenBalances.reduce(into: [String : Int]()) { dict, item in
            dict[item.mint] = item.balanceToken
        }
    }
    
    func getTokenBalance(tokenMint: String) async throws -> Int {
        let input = TokenBalanceInput(tokenMint: tokenMint)
        let res: BalanceResponse = try await callQuery("getTokenBalance", input: input, tokenRequired: true)
        return res.balance
    }
    
    func getTxData(buyTokenId: String, sellTokenId: String, sellQuantity: Int, slippageBps: Int? = nil) async throws -> TxData {
        let input = SwapInput(buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity, slippageBps: slippageBps)
        let res: TxData = try await callQuery("fetchSwap", input: input, tokenRequired: true)
        return res
    }
    
    func submitSignedTx(txBase64: String, signature: String) async throws -> TxIdResponse {
        let input = signedTxInput(signature: signature, base64Transaction: txBase64)
        let res: TxIdResponse = try await callMutation("submitSignedTransaction", input: input, tokenRequired: true)
        return res
    }
    
    func transferUsdc(fromAddress: String, toAddress: String, amount: Int) async throws -> String {
        // 1. Get the pre-signed transaction from the server
        let input = TransferInput(
            toAddress: toAddress,
            amount: String(amount),
            tokenId: USDC_MINT
        )
        let transfer: TransferResponse = try await callQuery("fetchTransferTx", input: input, tokenRequired: true)
        
        // 3. Sign using the Privy Embedded Wallet
        let provider = try privy.embeddedWallet.getSolanaProvider(for: fromAddress)
        let userSignature = try await provider.signMessage(message: transfer.transactionMessageBase64)
        
        // 4. Submit the signed transaction
        let response: TxIdResponse = try await callMutation(
            "submitSignedTransaction",
            input: signedTxInput(
                signature: userSignature,
                base64Transaction: transfer.transactionMessageBase64
            ),
            tokenRequired: true
        )
        
        return response.signature
    }
    
}
