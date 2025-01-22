//
//  OnrampView.swift
//  Tub
//
//  Created by Henry on 1/21/25.
//

import SwiftUI

struct OnrampView: View {
  @State private var selectedTab = 0
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    TabView(selection: $selectedTab) {
      CoinbaseOnrampView()
        .tabItem {
          Image("CoinbaseLogo")
            .opacity(selectedTab == 0 ? 0 : 1)

          Text("Coinbase")
        }
        .tag(0)

      NativeOnrampView()
        .tabItem {
          VStack {
            Image(systemName: "creditcard.fill")
            Text("Transfer")
          }
        }
        .tag(1)
    }
    .safeAreaInset(edge: .top) {
      ZStack {
        HStack {
          Spacer()
          Text("Deposit")
            .font(.headline)
          Spacer()
        }

        HStack {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .foregroundColor(.primary)
              .padding()
          }
          Spacer()
        }
      }
      .background(Color(UIColor.systemBackground))
    }
  }
}

#Preview {
  OnrampView()
    .environmentObject(UserModel.shared)
    .environmentObject(SolPriceModel.shared)
}
