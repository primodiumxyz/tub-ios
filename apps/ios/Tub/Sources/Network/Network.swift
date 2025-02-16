//
//  Network.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/10/2.
//

import Apollo
import Foundation
import Security

/**
 * This class is responsible for managing the network requests to the server and the GraphQL API.
 * It will handle the submission of buy and sell transactions to the server, as well as sending and receiving data to the GraphQL API through extensions.
*/
class Network {
  static let shared = Network()
  private var lastApiCallTime: Date = Date()
  private let tokenManager = TokenManager()

  // GraphQL
  private(set) lazy var graphQL = GraphQLManager()

  // tRPC
  private let baseURL: URL
  private let session: URLSession

  init() {
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
    let token = await tokenManager.getStoredToken()

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
    return try await callMutation(
      mutation, input: Optional<EmptyInput>.none, tokenRequired: tokenRequired)
  }

  func callQuery<T: Codable, I: Codable>(
    _ query: String,
    input: I? = nil,
    tokenRequired: Bool = false
  ) async throws -> T {
    let token = await tokenManager.getStoredToken()

    var urlComponents = URLComponents(
      url: baseURL.appendingPathComponent(query), resolvingAgainstBaseURL: true)!
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

  private func callQuery<T: Codable>(_ query: String, tokenRequired: Bool = false) async throws -> T
  {
    return try await callQuery(
      query, input: Optional<EmptyInput>.none, tokenRequired: tokenRequired)
  }

  // MARK: - JWT
  func getStoredToken(hardRefresh: Bool? = false) async -> String? {
    return await tokenManager.getStoredToken(hardRefresh: hardRefresh)
  }

  // MARK - Calls
  func getStatus() async throws -> Int {
    let response: StatusResponse = try await callQuery("getStatus")
    return response.status
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

  func getSolBalance() async throws -> Int {
    let res: BalanceResponse = try await callQuery("getSolBalance", tokenRequired: true)
    return res.balance
  }

  func getAllTokenBalances() async throws -> [String: Int] {
    let res: BulkTokenBalanceResponse = try await callQuery(
      "getAllTokenBalances", tokenRequired: true)
    return res.tokenBalances.reduce(into: [String: Int]()) { dict, item in
      dict[item.mint] = item.balanceToken
    }
  }

  func getTokenBalance(tokenMint: String) async throws -> Int {
    let input = TokenBalanceInput(tokenMint: tokenMint)
    let res: BalanceResponse = try await callQuery(
      "getTokenBalance", input: input, tokenRequired: true)
    return res.balance
  }

  func getTxData(
    buyTokenId: String, sellTokenId: String, sellQuantity: Int, slippageBps: Int? = nil
  ) async throws -> TxData {
    let input = SwapInput(
      buyTokenId: buyTokenId, sellTokenId: sellTokenId, sellQuantity: sellQuantity,
      slippageBps: slippageBps)
    let res: TxData = try await callQuery("fetchSwap", input: input, tokenRequired: true)
    return res
  }

  func submitSignedTx(txBase64: String, signature: String) async throws -> TxIdResponse {
    let input = signedTxInput(signature: signature, base64Transaction: txBase64)
    let res: TxIdResponse = try await callMutation(
      "submitSignedTransaction", input: input, tokenRequired: true)
    return res
  }

  func getEstimatedTransferFee() async throws -> Int {
    let res: EstimatedTransferFeeResponse = try await callQuery("getEstimatedTransferFee", tokenRequired: true)
    return res.estimatedFee
  }

  func transferUsdc(fromAddress: String, toAddress: String, amount: Int) async throws -> String {
    // 1. Get the pre-signed transaction from the server
    let input = TransferInput(
      toAddress: toAddress,
      amount: String(amount),
      tokenId: USDC_MINT
    )
    let transfer: TransferResponse = try await callQuery(
      "fetchTransferTx", input: input, tokenRequired: true)

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

  func transferSol(fromAddress: String, toAddress: String, amount: Int) async throws -> String {
    // 1. Get the pre-signed transaction from the server
    let input = TransferInput(
      toAddress: toAddress,
      amount: String(amount),
      tokenId: "SOLANA"
    )
    let transfer: TransferResponse = try await callQuery(
      "fetchTransferTx", input: input, tokenRequired: true)

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

  func startLiveActivity(
    tokenId: String, tokenPriceUsd: String, deviceToken: String, pushToken: String
  ) async throws {
    let input = StartLiveActivityInput(
      tokenMint: tokenId,
      tokenPriceUsd: tokenPriceUsd,
      deviceToken: deviceToken,
      pushToken: pushToken
    )
      let _: EmptyResponse = try await callMutation("startLiveActivity", input: input, tokenRequired: true)
  }

  func stopLiveActivity() async throws {
    let _: EmptyResponse = try await callMutation("stopLiveActivity", tokenRequired: true)
  }
}
