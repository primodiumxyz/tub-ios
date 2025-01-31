//


//  JWTActor.swift
//  Tub
//
//  Created by Henry on 12/23/24.
//

import Foundation
import Security

/**
 * This class is responsible for managing the JWT token for the user.
 * It is used to decode the JWT token and store it.
 * This will be used for authentication with the server.
*/
actor TokenManager {
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
                }
                
                do {
                    print("Token expired, refreshing session")
                    let newSession = try await privy.refreshSession()
                    storeToken(newSession.authToken)
                    return newSession.authToken
                } catch {
                    print("Failed to refresh session: \(error)")
                    return nil
                }
                
            }
            return nil
        default:
            return nil
        }
    }
}
