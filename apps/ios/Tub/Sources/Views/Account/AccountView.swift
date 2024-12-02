//
//  AccountView.swift
//  Tub
//
//  Created by Henry on 10/4/24.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var notificationHandler: NotificationHandler
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject private var userModel: UserModel
    @State private var isNavigatingToRegister = false
    @State private var isAirdropping = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showOnrampView = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if userModel.userId != nil {
                    AccountContentView(
                        isAirdropping: $isAirdropping,
                        showOnrampView: $showOnrampView
                    )
                }
                else {
                    UnregisteredAccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemBackground))
            .sheet(isPresented: $showOnrampView) {

                VStack {
                    HStack {
                        Text("Deposit")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button(action: { showOnrampView = false }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(.primary)
                                .font(.system(size: 16, weight: .medium))
                        }
                    }.padding(24)

                    CoinbaseOnrampView()
                }.background(Color(UIColor.systemBackground))
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.systemBackground))
    }
}

// New component for the header section
private struct AccountHeaderView: View {

    var body: some View {
        VStack(spacing: 8) {
            BalanceSection()
        }
    }
}

// New component for the balance section
private struct BalanceSection: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel

    var accountBalance: (balance: Int?, change: Int) {
        let balance = userModel.balanceLamps

        let adjustedChange = userModel.balanceChangeLamps

        return (balance, adjustedChange)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Account Balance")
                .font(.sfRounded(size: .lg, weight: .regular))
                .foregroundStyle(.secondary)

            if let balance = accountBalance.balance {
                let formattedBalance = priceModel.formatPrice(lamports: balance, maxDecimals: 2, minDecimals: 2)

                Text(formattedBalance)
                    .font(.sfRounded(size: .xl5, weight: .bold))
                    .foregroundStyle(.primary)
            }
            else {
                ProgressView()
            }

            if accountBalance.change > 0 {
                Text("\(priceModel.formatPrice(lamports: accountBalance.change, showSign: true, maxDecimals: 2))")

                // Format time elapsed
                Text("\(formatDuration(userModel.elapsedSeconds))")
                    .foregroundStyle(.secondary)
                    .font(.sfRounded(size: .sm, weight: .regular))

            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

// New component for action buttons
private struct ActionButtons: View {
    let isAirdropping: Bool
    @Binding var showOnrampView: Bool

    var body: some View {
        HStack(spacing: 24) {
            Spacer()

            // Add Transfer Button
            VStack(spacing: 8) {
                CircleButton(
                    icon: "arrow.left.arrow.right",
                    color: .tubAccent,
                    iconSize: 22,
                    action: {}
                ).disabled(true)

                Text("Transfer")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundStyle(.tubAccent)
                    .multilineTextAlignment(.center)
            }.frame(width: 90).opacity(0.7)

            // Add Funds Button
            VStack(spacing: 8) {
                CircleButton(
                    icon: "plus",
                    color: .tubAccent,
                    action: { showOnrampView = true }
                )

                Text("Add Funds")
                    .font(.sfRounded(size: .sm, weight: .medium))
                    .foregroundStyle(.tubAccent)
                    .multilineTextAlignment(.center)
            }.frame(width: 90)

            Spacer()
        }
        .padding(.horizontal)
    }
}

// New component for account settings
private struct AccountSettingsView: View {
    @EnvironmentObject private var userModel: UserModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Account Settings")
                    .font(.sfRounded(size: .xl, weight: .medium))
                    .foregroundStyle(.primary)

                NavigationLink(destination: AccountDetailsView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 24, height: 24, alignment: .center)
                        Text("Account Details")
                            .font(.sfRounded(size: .lg, weight: .regular))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color.primary)
                }

                NavigationLink(destination: SettingsView()) {
                    HStack(spacing: 16) {
                        Image(systemName: "gear")
                            .resizable()
                            .frame(width: 24, height: 24, alignment: .center)
                        Text("Settings")
                            .font(.sfRounded(size: .lg, weight: .regular))
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundStyle(Color.primary)
                }

                HStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                    Text("Support")
                        .font(.sfRounded(size: .lg, weight: .regular))
                    Spacer()
                    Image("Discord")
                        .resizable()
                        .frame(width: 32, height: 32, alignment: .center)
                        .cornerRadius(8)
                        .padding(.trailing, -4)
                    Text("Discord Server")
                        .font(.sfRounded(size: .lg, weight: .medium))
                }
                .foregroundStyle(.primary)

                // Logout Button
                IconTextButton(
                    icon: "rectangle.portrait.and.arrow.right",
                    text: "Logout",
                    textColor: Color.red,
                    action: { userModel.logout() }
                )

                Text(serverBaseUrl).foregroundStyle(.primary)
                    .font(.caption)
            }
            .padding()
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// New component for unregistered users
private struct UnregisteredAccountView: View {
    var body: some View {
        RegisterView().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// Main content view for registered users
private struct AccountContentView: View {
    @Binding var isAirdropping: Bool
    @Binding var showOnrampView: Bool

    var body: some View {
        VStack(spacing: 24) {
            AccountHeaderView()
            ActionButtons(
                isAirdropping: isAirdropping,
                showOnrampView: $showOnrampView
            )
            AccountSettingsView()
            Spacer()
        }
    }
}
