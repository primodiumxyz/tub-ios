//
//  CreateWalletView.swift
//  Tub
//
//  Created by Henry on 11/1/24.
//
import SwiftUI

struct CreateWalletView : View {
    @EnvironmentObject private var errorHandler: ErrorHandler

    func handleWalletCreation() {
        Task {
            do {
                // Ensure we're authenticated first
                guard case .authenticated = privy.authState else { return }
                
                // Get the current embedded wallet state
                let walletState = privy.embeddedWallet.embeddedWalletState
                
                // Check if we need to create a wallet
                switch walletState {
                case .notCreated:
                    // Create a new embedded wallet
                    print("Creating new embedded wallet")
                    _ = try await privy.embeddedWallet.createWallet(allowAdditional: false)
                case .connected(let wallets):
                    print("Wallet already exists: \(wallets)")
                default:
                    print("Wallet state: \(walletState.toString)")
                }
            } catch {
                errorHandler.show(error)
            }
        }
    }
    
    var body: some View {
        Button(action: handleWalletCreation) {
            Text("Create Wallet")
        }
    }
    
}
