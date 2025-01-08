//
//  Structs.swift
//  Tub
//
//  Created by Henry on 12/12/24.
//


// MARK: - Input Types

struct EmptyInput: Codable {}

struct TokenActionInput: Codable {
    // Wrap in a dictionary structure that matches server expectation
    private enum CodingKeys: String, CodingKey {
        case tokenId, amount, tokenPrice
    }
    
    let tokenId: String
    let amount: String
    let tokenPrice: String
}

struct TransferInput: Codable {
    let toAddress: String
    let amount: String
    let tokenId: String
}

struct SwapInput: Codable {
    let buyTokenId: String
    let sellTokenId: String
    let sellQuantity: Int
    let slippageBps: Int?
}

struct TokenBalanceInput: Codable {
    let tokenMint: String
}

struct TokenPurchaseInput: Codable {
    let tokenMint: String
    let tokenAmount: String
    let tokenPriceUsd: String
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct TokenSaleInput: Codable {
    let tokenMint: String
    let tokenAmount: String
    let tokenPriceUsd: String
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct TabSelectedInput: Codable {
    let tabName: String
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct LoadingTimeInput: Codable {
    let identifier: String
    let timeElapsedMs: Int
    let attemptNumber: Int
    let totalTimeMs: Int
    let averageTimeMs: Int
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct AppDwellTimeInput: Codable {
    let dwellTimeMs: Int
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct TabDwellTimeInput: Codable {
    let tabName: String
    let dwellTimeMs: Int
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct TokenDwellTimeInput: Codable {
    let tokenMint: String
    let dwellTimeMs: Int
    let source: String
    let errorDetails: String?
    let userAgent: String
    let buildVersion: String
    let userWallet: String
}

struct StartLiveActivityInput: Codable {
    let tokenMint: String
    let tokenPriceUsd: String
    let pushToken: String
}

// MARK: - Response Types
struct ResponseWrapper<T: Codable>: Codable {
    struct ResultWrapper: Codable {
        let data: T
    }
    let result: ResultWrapper
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
    let signature: String
    let timestamp: Int?
}

struct ErrorResponse: Codable {
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

struct EmptyResponse: Codable {}

struct TransferResponse: Codable {
    let transactionMessageBase64: String
}

struct StatusResponse: Codable {
    let status: Int
}

struct BalanceResponse : Codable {
    let balance: Int
}

struct TokenBalanceItem: Codable {
    let mint: String
    let balanceToken: Int
}

struct BulkTokenBalanceResponse: Codable {
    let tokenBalances: [TokenBalanceItem]
}
