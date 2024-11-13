//
//  CreateWalletView.swift
//  Tub
//
//  Created by Henry on 11/1/24.
//
import SwiftUI

struct CreateWalletView : View {
    @EnvironmentObject private var errorHandler: ErrorHandler
    @State private var isLoading = false
    @State private var hasFailed = false
    
    func createEmbeddedWallet() {
        Task {
            do {
                isLoading = true
                // Ensure we're authenticated first
                guard case .authenticated = privy.authState else {
                    isLoading = false
                    return
                }
                
                // Get the current embedded wallet state
                let walletState = privy.embeddedWallet.embeddedWalletState
                
                // Check if we need to create a wallet
                switch walletState {
                case .notCreated:
                    print("No wallet found, creating embedded wallet...")
                    let _ = try await privy.embeddedWallet.createWallet(chainType: .solana, allowAdditional: false)
                case .connected(let wallets):
                    if wallets.contains(where: { $0.chainType == .solana }) {
                        print("Wallet already created")
                    } else {
                        print("Eth wallet exists, creating solana wallet...")
                        let _ = try await privy.embeddedWallet.createWallet(chainType: .solana, allowAdditional: false)
                    }
                default:
                    print("Wallet state: \(walletState.toString)")
                }
                isLoading = false
            } catch {
                isLoading = false
                errorHandler.show(error)
            }
        }
    }
    
    
    var body: some View {
        VStack {
            if isLoading {
                Text("Creating Tub Wallet...")
            } else if hasFailed {
                LoginErrorView(
                    errorMessage: "Failed to create your Tub wallet. Please try again.",
                    retryAction: createEmbeddedWallet
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black).foregroundStyle(.white)
        .onAppear {
            createEmbeddedWallet()
        }
    }
    
}

#Preview {
    CreateWalletView()
}
