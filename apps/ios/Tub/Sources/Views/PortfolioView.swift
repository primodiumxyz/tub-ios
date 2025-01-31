//
//  TokenBalancesView.swift
//  Tub
//
//  Created by Henry on 12/4/24.
//

import SwiftUI

/**
 * This view is responsible for displaying the user's portfolio.
*/
struct PortfolioView: View {
  @EnvironmentObject private var userModel: UserModel
  @EnvironmentObject private var priceModel: SolPriceModel
  @State private var isRefreshing = false

  var totalPortfolioValue: Double {
    let usdcValue = priceModel.usdcToUsd(usdc: userModel.usdcBalance ?? 0)
    let tokenValue = userModel.tokenPortfolio.reduce(0.0) { total, key in
      if let token = userModel.tokenData[key] {
        let price = token.liveData?.priceUsd ?? 0
        let balance = Double(token.balanceToken)
        let decimals = Double(token.metadata.decimals)
        return total + (price * balance / pow(10, decimals))
      }
      return total
    }
    return Double(usdcValue) + tokenValue
  }

  var body: some View {
    VStack {

      HStack {
        Spacer()
        Button {
          Task {

            isRefreshing = true
            do {
              try await userModel.refreshPortfolio()
            } catch {
              print("error, unable to refresh portfolio \(error)")
              isRefreshing = false
            }
            isRefreshing = false
          }
        } label: {
          Image(systemName: "arrow.clockwise")
            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
            .animation(
              isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
              value: isRefreshing)
        }
        .padding(.horizontal)
      }
      HStack {
        Text("Portfolio")
          .font(.sfRounded(size: .lg, weight: .medium))
        Spacer()
        Text(priceModel.formatPrice(usd: totalPortfolioValue))
          .font(.sfRounded(size: .lg, weight: .medium))
      }
      .padding()
      .padding(.horizontal)

      HStack {
        VStack(alignment: .leading) {
          Text("USDC")
            .font(.sfRounded(size: .lg, weight: .medium))
        }

        Spacer()

        VStack {
          Text("Value: \(priceModel.formatPrice(usdc: userModel.usdcBalance ?? 0))")
          Text("\(userModel.usdcBalance ?? 0)")
        }
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .padding(.horizontal)

      if userModel.tokenPortfolio.count == 0 {
        Text("No tokens")
              .foregroundStyle(.tubText)
              .frame(maxHeight: .infinity)
      } else {

        List {

          ForEach(userModel.tokenPortfolio, id: \.self) { key in
            if let token = userModel.tokenData[key], token.balanceToken > 0 {
              TokenRowView(token: token)
            }
          }
        }
      }
    }
  }
}

struct TokenRowView: View {

  @EnvironmentObject private var priceModel: SolPriceModel
  var token: TokenData
  var tokenValue: Double {
    let price = token.liveData?.priceUsd ?? 0
    let balance = token.balanceToken
    let decimals = token.metadata.decimals
    return price * Double(balance) / pow(10, Double(decimals))
  }
  var body: some View {
    HStack {
      if let url = URL(string: token.metadata.imageUri) {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } placeholder: {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 32, height: 32)
        }
      } else {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.2))
          .frame(width: 32, height: 32)
      }

      VStack(alignment: .leading) {
        Text(token.metadata.name)
          .font(.sfRounded(size: .lg, weight: .medium))
        Text(token.metadata.symbol)
          .font(.sfRounded(size: .sm))
          .foregroundStyle(.secondary)
      }

      Spacer()

      VStack {
        Text("Value: \(priceModel.formatPrice(usd: tokenValue))")
          .font(.sfRounded(size: .lg, weight: .medium))
        Text("Price: \(token.liveData?.priceUsd ?? 0)")
          .font(.sfRounded(size: .xs, weight: .light))
        Text("Balance: \(formatLargeNumber(Double(token.balanceToken)))")
          .font(.sfRounded(size: .xs, weight: .light))
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  @Previewable @StateObject var priceModel = {
    let model = SolPriceModel.shared
    spoofPriceModelData(model)
    return model
  }()

  @Previewable @StateObject var userModel = UserModel.shared
  PortfolioView()
    .environmentObject(priceModel)
    .environmentObject(userModel)
}
