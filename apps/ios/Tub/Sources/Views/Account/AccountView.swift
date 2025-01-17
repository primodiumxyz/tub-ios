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
  @State private var showWithdrawView = false
  @State private var errorMessage: String = ""

  var body: some View {
    Group {
      if userModel.userId != nil {
        VStack(spacing: 18) {
          BalanceSection()
          ActionButtons(
            isAirdropping: isAirdropping,
            showOnrampView: $showOnrampView,
            showWithdrawView: $showWithdrawView
          )

          TokenHistoryPreview()

          AccountSettingsView()
          Spacer()
        }
      } else {
        RegisterView().frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
    .sheet(isPresented: $showWithdrawView) {
      WithdrawView()
        .withNotificationBanner()
    }
    .sheet(isPresented: $showOnrampView) {
      CoinbaseOnrampView()
        .withNotificationBanner()
    }
    .padding()
    .presentationDragIndicator(.visible)
    .presentationBackground(Color(UIColor.systemBackground))
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)

  }
}

// New component for the balance section
private struct BalanceSection: View {
  @EnvironmentObject private var userModel: UserModel
  @EnvironmentObject private var priceModel: SolPriceModel

  var deltaUsd: Double {
    guard let initialBalance = userModel.initialPortfolioBalance,
      let currentBalanceUsd = userModel.portfolioBalanceUsd
    else { return 0 }
    return currentBalanceUsd - initialBalance
  }

  var body: some View {
    VStack(spacing: 8) {
      Text("Account Balance")
        .font(.sfRounded(size: .lg, weight: .regular))
        .foregroundStyle(.secondary)

      if let balance = userModel.portfolioBalanceUsd {
        let formattedBalance = priceModel.formatPrice(usd: balance, maxDecimals: 2, minDecimals: 2)

        Text(formattedBalance)
          .font(.sfRounded(size: .xl5, weight: .bold))
          .foregroundStyle(.primary)
      } else {
        ProgressView()
      }

      if deltaUsd > 0 {
        Text("\(priceModel.formatPrice(usd: deltaUsd, showSign: true, maxDecimals: 2))")

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

private struct TokenHistoryPreview: View {
  @EnvironmentObject private var userModel: UserModel

  func handleRefreshTxs() {
    Task {
      try? await userModel.refreshTxs()
    }
  }

  var body: some View {
    NavigationLink(destination: HistoryView()) {
      VStack {
        Rectangle()
          .fill(.tubText.opacity(0.25))
          .frame(height: 1)
          .padding(.bottom, 6)
        HStack {
          Text("Last Trade")
            .font(.sfRounded(size: .xl, weight: .medium))
          Spacer()
          Text("View All")
            .font(.sfRounded(size: .base, weight: .regular))
          Image(systemName: "chevron.right")
        }.foregroundStyle(.tubText)
        if userModel.txs == nil {
          LoadingBox(height: 40)
        }  else if let txs = userModel.txs, txs.count > 0 {
              TransactionRow(transaction: txs[0])
            .frame(height: 40)
        } else {
          HStack {
            Spacer()
            Text("No recent trades")
              .font(.sfRounded(size: .base, weight: .regular))
              .foregroundStyle(.secondary)
            Spacer()
          }.frame(height: 40)
        }

        Rectangle()
          .fill(.tubText.opacity(0.25))
          .frame(height: 1)
          .padding(.top, 6)
      }
    }
    .clipped()
    .onAppear {
      handleRefreshTxs()
    }
    .onChange(of: userModel.walletAddress) { handleRefreshTxs() }
  }
}

private struct TransactionRow: View {
  let transaction: TransactionData
  @EnvironmentObject private var priceModel: SolPriceModel

  var body: some View {
    HStack {
      ImageView(imageUri: transaction.imageUri, size: 32)
        .cornerRadius(8)

      VStack(alignment: .leading) {
        HStack {
          Text(transaction.isBuy ? "Buy" : "Sell")
            .font(.sfRounded(size: .base, weight: .bold))
            .foregroundStyle(.tubText)
          Text(transaction.name.isEmpty ? transaction.mint.truncatedAddress() : transaction.name)
            .font(.sfRounded(size: .base, weight: .bold))
            .lineLimit(1)
            .truncationMode(.tail)
            .offset(x: -2)
        }

      }
      Spacer()
      VStack(alignment: .trailing) {
        let price = priceModel.formatPrice(usd: transaction.valueUsd, showSign: true)
        Text(price)
          .font(.sfRounded(size: .base, weight: .bold))
          .foregroundStyle(transaction.isBuy ? Color.red : Color.green)

        let quantity = priceModel.formatPrice(
          lamports: abs(transaction.quantityTokens),
          showUnit: false
        )
        HStack {
          Text(quantity)
            .font(.sfRounded(size: .xs, weight: .regular))
            .foregroundStyle(.tubBuyPrimary)
            .offset(x: 4, y: 2)

          Text(transaction.symbol)
            .font(.sfRounded(size: .xs, weight: .regular))
            .foregroundStyle(.tubBuyPrimary)
            .offset(y: 2)
        }
      }
      .padding(.horizontal, 8)
    }
  }
}

// New component for action buttons
private struct ActionButtons: View {
  let isAirdropping: Bool
  @Binding var showOnrampView: Bool
  @Binding var showWithdrawView: Bool

  var body: some View {
    HStack(spacing: 24) {
      Spacer()

      // Add Transfer Button
      VStack(spacing: 8) {
        CircleButton(
//          icon: "arrow.left.arrow.right",
            icon: "Transfer",
            isSystemIcon: false,
          color: .tubAccent,
          iconSize: 44,
          action: { showWithdrawView.toggle() }
        )

        Text("Transfer")
          .font(.sfRounded(size: .sm, weight: .medium))
          .foregroundStyle(.tubAccent)
          .multilineTextAlignment(.center)
      }.frame(width: 90)

      // Add Funds Button
      VStack(spacing: 8) {
        CircleButton(
            icon: "Add",
            isSystemIcon: false,
          color: .tubAccent,
            iconSize: 44,
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
    VStack(alignment: .leading, spacing: 24) {
      Text("Account Settings")
        .font(.sfRounded(size: .xl, weight: .medium))
        .foregroundStyle(.primary)

      NavigationLink(destination: AccountDetailsView()) {
        HStack(spacing: 16) {
          Image(systemName: "person.circle")
            .resizable()
            .frame(width: 24, height: 24, alignment: .center)
          Text("Profile")
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
          Text("Preferences")
            .font(.sfRounded(size: .lg, weight: .regular))
          Spacer()
          Image(systemName: "chevron.right")
        }
        .foregroundStyle(Color.primary)
      }

      Link(destination: URL(string: "https://t.me/tubalpha")!) {
        HStack(spacing: 16) {
          Image("Telegram")
            .resizable()
            .frame(width: 24, height: 24, alignment: .center)
          Text("Join Telegram")
            .font(.sfRounded(size: .lg, weight: .regular))
          Spacer()
          Image(systemName: "chevron.right")
        }
      }
      .foregroundStyle(.primary)

      // Logout Button
      IconTextButton(
        icon: "Logout",
        isSystemIcon: false,
        text: "Logout",
        textColor: Color.red,
        iconSize: CGSize(width: 36, height: 36),
        action: { userModel.logout() }
      )

    }
    .foregroundStyle(Color.primary)
  }
}

#Preview {
  @Previewable @StateObject var userModel = UserModel.shared
  @Previewable @StateObject var priceModel = {
    let model = SolPriceModel.shared
    spoofPriceModelData(model)
    return model
  }()

  @Previewable @StateObject var notificationHandler = NotificationHandler()

  NavigationStack {
    AccountView()
  }
  .environmentObject(priceModel)
  .environmentObject(userModel)
  .environmentObject(notificationHandler)
}
