//
//  TokenBalancesView.swift
//  Tub
//
//  Created by Henry on 12/4/24.
//

import SwiftUI

struct TokenBalancesView: View {
    @EnvironmentObject private var userModel: UserModel
    @EnvironmentObject private var priceModel: SolPriceModel
    @State private var isRefreshing = false
    
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
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .padding(.horizontal)
            }
            
            if userModel.tokenPortfolio.count == 0 {
                Text("No tokens").foregroundStyle(.tubText)
            }
            
            else {
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
    var token: TokenData
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
            
            Text("\(token.balanceToken)")
                .font(.sfRounded(size: .lg, weight: .medium))
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
    TokenBalancesView()
        .environmentObject(priceModel)
        .environmentObject(userModel)
}
