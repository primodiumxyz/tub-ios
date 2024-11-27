//
//  AccountDetailsView.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/12.
//

import Foundation
import PrivySDK
import SwiftUI

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

    var linkedAccounts: (email: String?, phone: String?, embeddedWallets: [PrivySDK.EmbeddedWallet]) {
        userModel.getLinkedAccounts()
    }

    var body: some View {
        if let userId = userModel.userId, let wallet = userModel.walletAddress {
            NavigationStack {
                VStack {
                    // Account Information List
                    VStack(spacing: 24) {
                        DetailRow(
                            title: "Account ID",
                            value: truncateString(userId)
                        ) {
                            IconButton(
                                icon: "doc.on.doc",
                                color: .tubText,
                                size: 16,
                                action: {
                                    UIPasteboard.general.string = userId
                                }
                            )
                        }

                        if let email = linkedAccounts.email {
                            DetailRow(title: "Email", value: email)
                        }

                        if let phone = linkedAccounts.phone {
                            DetailRow(title: "Phone", value: phone)
                        }

                        Divider()
                            .frame(height: 1)
                            .overlay(Color.gray.opacity(0.5))

                        DetailRow(
                            title: "Wallet",
                            value: truncateString(wallet)
                        ) {
                            IconButton(
                                icon: "doc.on.doc",
                                color: .tubText,
                                size: 16,
                                action: {
                                    UIPasteboard.general.string = wallet  // Copy full address
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 24)

                    Spacer()
                }
                .onChange(of: userId) { _, newValue in
                    if newValue.isEmpty {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .navigationBarBackButtonHidden(false)
                .navigationTitle("Account Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Account Details")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                    }
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        else {
            EmptyView()
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

            Spacer()

            Text(value)
                .font(.sfRounded(size: .lg, weight: .regular))

            if let icon = trailingIcon {
                icon()
            }
        }
    }
}
