//
//  Privy.swift
//  Tub
//
//  Created by Henry on 10/30/24.
//
import SwiftUI

final class UserManager {
    @AppStorage("userId") public var userId: String = "" {
        didSet {
            userUpdateCallback?(userId)
        }
    }
    static let shared = UserManager()
    
    private var userUpdateCallback: ((String) -> Void)?
    
    private init() {}
    
    func onUserUpdate(_ callback: @escaping (String) -> Void) {
        userUpdateCallback = callback
        // Trigger initial callback with current value
        callback(userId)
    }
    
    func register(onRegister: ( (String) -> Void)?) {
        userId = UUID().uuidString
        onRegister?(userId)
    }
    
    func logout(onLogout: (() -> Void)?) {
        userId = ""
        onLogout?()
    }
}
