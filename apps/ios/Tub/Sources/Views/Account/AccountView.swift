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
    NavigationStack {
      VStack(spacing: 24) {
        if userModel.userId != nil {
          AccountContentView(
            isAirdropping: $isAirdropping,
            showOnrampView: $showOnrampView,
            showWithdrawView: $showWithdrawView
          )
        } else {
          UnregisteredAccountView()
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
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
    .presentationDragIndicator(.visible)
    .presentationBackground(Color(UIColor.systemBackground))

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
          icon: "arrow.left.arrow.right",
          color: .tubAccent,
          iconSize: 22,
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
      NavigationLink(destination: PortfolioView()) {
        HStack(spacing: 16) {
          Image(systemName: "book.closed.fill.circle")
            .resizable()
            .frame(width: 24, height: 24, alignment: .center)
          Text("Portfolio")
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
  @Binding var showWithdrawView: Bool

  var body: some View {
    VStack(spacing: 24) {
      AccountHeaderView()
      ActionButtons(
        isAirdropping: isAirdropping,
        showOnrampView: $showOnrampView,
        showWithdrawView: $showWithdrawView
      )
      AccountSettingsView()
      Spacer()
    }
  }
}
