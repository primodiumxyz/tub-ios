//
//  AccountDetailsView.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/13.
//

import SwiftUI
import Foundation

struct AccountDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userModel: UserModel
    @Environment(\.presentationMode) var presentationMode
    
    func truncateString(_ str: String, prefixLength: Int = 6, suffixLength: Int = 4) -> String {
        guard str.count > (prefixLength + suffixLength + 3) else { return str }
        
        let prefix = String(str.prefix(prefixLength))
        let suffix = String(str.suffix(suffixLength))
        return "\(prefix)...\(suffix)"
    }
    
    var body: some View {
        NavigationStack {
            VStack() {
                // Account Information List
                VStack(spacing: 24) {
                    // Commented out for now
                    // DetailRow(title: "Username", value: "Primo Rhino")
                    
                    DetailRow(
                        title: "Account ID", 
                        value: truncateString(userModel.userId)
                    ) {
                        Button(action: {
                            UIPasteboard.general.string = userModel.userId
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(AppColors.white)
                        }
                    }
                    
                    DetailRow(title: "Email", value: "rhino@primodium.com")
                    DetailRow(title: "Phone", value: "+1 (213)-345-5678")
                    
                    Divider()
                        .frame(height: 1)
                        .overlay(Color.gray.opacity(0.5))
                    
                    DetailRow(
                        title: "Wallet", 
                        value: truncateString(userModel.walletAddress)
                    ) {
                        Button(action: {
                            UIPasteboard.general.string = userModel.walletAddress // Copy full address
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(AppColors.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                Spacer()
            }
            .onChange(of: userModel.userId) { newValue in
                if newValue.isEmpty {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Account Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.aquaGreen)
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Account Details")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(AppColors.white)
                }
            }
            .background(AppColors.black)
        }
    }
}

// Helper view for consistent row styling
struct DetailRow: View {
    let title: String
    let value: String
    var trailingIcon: (() -> AnyView)? = nil
    
    init(title: String, value: String, trailingIcon: (() -> AnyView)? = nil) {
        self.title = title
        self.value = value
        self.trailingIcon = trailingIcon
    }
    
    init(title: String, value: String, @ViewBuilder trailingIcon: @escaping () -> some View) {
        self.title = title
        self.value = value
        self.trailingIcon = { AnyView(trailingIcon()) }
    }
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.sfRounded(size: .lg, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.sfRounded(size: .lg, weight: .regular))
                .foregroundColor(.white)
            
            if let icon = trailingIcon {
                icon()
            }
        }
    }
}

#Preview {
    AccountDetailsView()
        .environmentObject(UserModel(userId: "preview"))
} 
