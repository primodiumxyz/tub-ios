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
    let response: StatusResponse = try await callQuery("getStatus")
    return response.status
  }

  func recordClientEvent(event: ClientEvent) async throws {
    let input = EventInput(event: event)
    let _: EmptyResponse = try await callMutation("recordClientEvent", input: input)
  }

  func callMutation<T: Codable, I: Codable>(
    _ mutation: String,
    input: I? = nil
  ) async throws -> T {
    // Get token asynchronously
    let token = await getStoredToken()

    let url = baseURL.appendingPathComponent(mutation)
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

  private func callMutation<T: Codable>(_ mutation: String) async throws -> T {
    return try await callMutation(mutation, input: Optional<EmptyInput>.none)
  }
  func callQuery<T: Codable, I: Codable>(
    _ query: String,
    input: I? = nil
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
    }
    
    let (data, _) = try await session.data(for: request)
    
    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
        print("Error: \(errorResponse.error.message)")
        throw TubError.serverError(reason: errorResponse.error.message)
    }
    
    let decodedResponse = try JSONDecoder().decode(ResponseWrapper<T>.self, from: data)
    return decodedResponse.result.data
  }

  private func callQuery<T: Codable>(_ query: String) async throws -> T {
    return try await callQuery(query, input: Optional<EmptyInput>.none)
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

  func getStoredToken() async -> String? {
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
    let res: BalanceResponse = try await callQuery("getBalance")
    return res.balance
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
      (
        mint: account.account.data.mint.base58EncodedString,
        Int(account.account.data.lamports)
      )
    }
  }

  func getUsdcBalance() async throws -> Int {
    return try await getTokenBalance(tokenMint: USDC_MINT)
  }

  func getTokenBalance(tokenMint: String) async throws -> Int {
    let input = TokenBalanceInput(tokenMint: tokenMint)
    let res: BalanceResponse = try await callQuery("getTokenBalance", input: input)
    return res.balance
  }

  func getTxData(buyTokenId: String, sellTokenId: String, sellQuantity: Int) async throws -> TxData
  {
    let input = SwapInput(
      buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity)
    let res: TxData = try await callQuery("fetchSwap", input: input)
    return res
  }

  func submitSignedTx(txBase64: String, signature: String) async throws -> TxIdResponse {
    let input = signedTxInput(signature: signature, base64Transaction: txBase64)
    let res: TxIdResponse = try await callMutation("submitSignedTransaction", input: input)
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
    let transfer: TransferResponse = try await callQuery("getSignedTransfer", input: input)

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
