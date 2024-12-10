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
import SolanaSwift
import UIKit

class Network {
    static let shared = Network()
    private var lastApiCallTime: Date = Date()

    // graphql
    private let httpTransport: RequestChainNetworkTransport
    private let webSocketTransport: WebSocketTransport
    private let solana: JSONRPCAPIClient

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
        solana = JSONRPCAPIClient(endpoint: APIEndPoint(address: solanaUrl, network: .mainnetBeta))
    }

    // MARK: - Calls
    func getStatus() async throws -> Int {
        let response: StatusResponse = try await callProcedure("getStatus")
        return response.status
    }

    func recordClientEvent(event: ClientEvent) async throws {
        let input = EventInput(event: event)
        let _: EmptyResponse = try await callProcedure("recordClientEvent", input: input)
    }

    // MARK: - Call Procedure
    private func callProcedure<T: Codable, I: Codable>(
        _ procedure: String,
        input: I? = nil
    ) async throws -> T {
        // Get token asynchronously
        let token = await getStoredToken()

        let url = baseURL.appendingPathComponent(procedure)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
        let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
        return decodedResponse.result.data
    }

    private func callProcedure<T: Codable>(_ procedure: String) async throws -> T {
        return try await callProcedure(procedure, input: Optional<EmptyInput>.none)
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

    private func getStoredToken() async -> String? {
        switch privy.authState {
        case .authenticated(let authSession):
            let token = authSession.authToken
            // Check if token is expired
            if let decodedToken = decodeJWT(token),
                let exp = decodedToken["exp"] as? TimeInterval
            {
                let expirationDate = Date(timeIntervalSince1970: exp)
                if expirationDate > Date() {
                    return token
                }
                else {
                    do {
                        print("Token expired, refreshing session")
                        let newSession = try await privy.refreshSession()
                        return newSession.authToken
                    }
                    catch {
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

    func getBalance(address: String) async throws -> Int {
        let res = try await solana.getBalance(account: address)
        return Int(res)
    }

    func getTokenBalances(address: String) async throws -> [(mint: String, balanceToken: Int)] {
        let params = OwnerInfoParams(
            mint: nil,
            programId: TOKEN_PROGRAM_ID
        )
        let tokenAccounts = try await solana.getTokenAccountsByOwner(
            pubkey: address,
            params: params,
            configs: RequestConfiguration(encoding: "base64")
        )

        return tokenAccounts.map { account in
            (mint: account.account.data.mint.base58EncodedString,
            Int(account.account.data.lamports))
        }
    }

    func getUsdcBalance(address: String) async throws -> Int {
        return try await getTokenBalance(address: address, tokenMint: USDC_MINT)
    }

    func getTokenBalance(address: String, tokenMint: String) async throws -> Int {
        let params = OwnerInfoParams(
            mint: tokenMint,
            programId: nil
        )
        let tokenAccounts = try await solana.getTokenAccountsByOwner(
            pubkey: address,
            params: params,
            configs: RequestConfiguration(encoding: "base64")
        )

        // Return 0 if no token account found
        guard let firstAccount = tokenAccounts.first else {
            return 0
        }

        return Int(firstAccount.account.data.lamports)
    }

    func getTxData(buyTokenId: String, sellTokenId: String, sellQuantity: Int) async throws -> TxData {
        let input = SwapInput(buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity)
        let res: TxData = try await callProcedure("fetchSwap", input: input)
        return res
    }

    func submitSignedTx(txBase64: String, signature: String) async throws -> TxIdResponse {
        let input = signedTxInput(signature: signature, base64Transaction: txBase64)
        let res: TxIdResponse = try await callProcedure("submitSignedTransaction", input: input)
        return res
    }

    func transferUsdc(fromAddress: String, toAddress: String, amount: Int) async throws -> String {
        // 1. Constants and input preparation
        let usdcTokenId = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"
        let input = TransferInput(
            fromAddress: fromAddress,
            toAddress: toAddress,
            amount: String(amount),
            tokenId: usdcTokenId
        )

        // 2. Get signed transaction from server
        let transfer: TransferResponse = try await callProcedure("getSignedTransfer", input: input)

        // 3. Parse transaction data
        guard let messageData = Data(base64Encoded: transfer.transactionBase64) else {
            throw TubError.parsingError
        }
        var tx = try Transaction.from(data: messageData)

        // 4. Setup required keys and provider
        let feePayerPublicKey = try PublicKey(string: transfer.signerBase58)
        let fromPublicKey = try PublicKey(string: fromAddress)

        // 5. Add signatures in correct order
        // Fee payer signature must be first

        let signatureData = Data(base64Encoded: transfer.signatureBase64)
        let feePayerSignature = Signature(
            signature: signatureData,
            publicKey: feePayerPublicKey
        )

        try tx.addSignature(feePayerSignature)

        // User signature
        // Serialize the transaction for signing as base64
        let message = try tx.compileMessage().serialize().base64EncodedString()

        // Sign using the Privy Embedded Wallet.

        let provider = try privy.embeddedWallet.getSolanaProvider(for: fromAddress)
        let userSignatureMsg = try await provider.signMessage(message: message)

        let userSignature = Signature(
            signature: Data(base64Encoded: userSignatureMsg),
            publicKey: fromPublicKey
        )

        try tx.addSignature(userSignature)

        // 6. Send transaction
        //        let txId = try await solana.simulateTransaction(transaction: tx.serialize().base64EncodedString())
        let txId = try await solana.sendTransaction(transaction: tx.serialize().base64EncodedString())

        return txId
    }
}

// MARK: - Response Types
struct ResponseWrapper<T: Codable>: Codable {
    struct ResultWrapper: Codable {
        let data: T
    }
    let result: ResultWrapper
}

struct SwapInput: Codable {
    let buyTokenId: String
    let sellTokenId: String
    let sellQuantity: Int
}

struct TxData: Codable {
    let transactionMessageBase64: String
    let buyTokenId: String
    let sellTokenId: String
    let sellQuantity: Int
    let hasFee: Bool
    let timestamp: Int
}

struct signedTxInput: Codable {
    let signature: String
    let base64Transaction: String
}

struct TxIdResponse: Codable {
    let txId: String
}
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

struct TransferInput: Codable {
    let fromAddress: String
    let toAddress: String
    let amount: String
    let tokenId: String
}

struct TransferResponse: Codable {
    let transactionBase64: String
    let signatureBase64: String
    let signerBase58: String
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

struct ClientEvent {
    let eventName: String
    let source: String
    var errorDetails: String? = nil
    var metadata: [[String: Any]]? = nil

    init(
        eventName: String,
        source: String,
        metadata: [[String: Any]]? = nil,
        errorDetails: String? = nil
    ) {
        self.eventName = eventName
        self.source = source
        self.metadata = metadata
        self.errorDetails = errorDetails
    }
}

// MARK: - Input Types
struct RegisterUserInput: Codable {
    let username: String
    let airdropAmount: String?
}

struct TokenActionInput: Codable {
    // Wrap in a dictionary structure that matches server expectation
    private enum CodingKeys: String, CodingKey {
        case tokenId, amount, tokenPrice
    }

    let tokenId: String
    let amount: String
    let tokenPrice: String
}

struct RegisterTokenInput: Codable {
    let name: String
    let symbol: String
    let supply: String?
    let uri: String?
}

struct AirdropInput: Codable {
    let amount: String
}

struct EventInput: Codable {
    let userAgent: String
    let buildVersion: String?
    let errorDetails: String?
    let eventName: String
    let source: String
    let metadata: String?  // Keep as string internally

    init(event: ClientEvent) {
        let device = UIDevice.current
        let userAgent = "\(device.systemName) \(device.systemVersion) \(device.name)"

        self.userAgent = userAgent
        self.source = event.source
        self.eventName = event.eventName
        self.errorDetails = event.errorDetails

        // Merge all metadata dictionaries into one
        if let metadata = event.metadata {
            var mergedMetadata: [String: Any] = [:]
            for dict in metadata {
                mergedMetadata.merge(dict) { current, _ in current }
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: mergedMetadata),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                self.metadata = jsonString
            }
            else {
                self.metadata = nil
            }
        }
        else {
            self.metadata = nil
        }

        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        {
            self.buildVersion = "\(version) (\(build))"
        }
        else {
            self.buildVersion = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userAgent, forKey: .userAgent)
        try container.encode(eventName, forKey: .eventName)
        try container.encode(source, forKey: .source)
        if let errorDetails = errorDetails {
            try container.encode(errorDetails, forKey: .errorDetails)
        }
        if let buildVersion = buildVersion {
            try container.encode(buildVersion, forKey: .buildVersion)
        }
        if let metadata = metadata {
            try container.encode(metadata, forKey: .metadata)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case userAgent
        case eventName
        case errorDetails
        case source
        case buildVersion
        case metadata
    }
}

private struct EmptyInput: Codable {}
