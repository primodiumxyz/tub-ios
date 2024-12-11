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

    var body: some View {
        VStack {
            if userModel.tokenPortfolio.count == 0 {
                Text("No tokens").foregroundStyle(.tubText)
            }
            
            else {
                List {
                    ForEach(Array(userModel.tokenPortfolio.keys), id: \.self) { key in
                        if let token = userModel.tokenPortfolio[key], token.balanceToken > 0 {
                        
                        HStack {
                            if let imageUrl = token.metadata?.imageUrl, let url = URL(string: imageUrl) {
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
                            }
                            else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 32, height: 32)
                            }


                            VStack(alignment: .leading) {
                                if let name = token.metadata?.name {
                                    Text(name)
                                        .font(.sfRounded(size: .lg, weight: .medium))
                                }
                                if let symbol = token.metadata?.symbol {
                                    Text(symbol)
                                        .font(.sfRounded(size: .sm))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text("\(token.balanceToken)")
                                .font(.sfRounded(size: .lg, weight: .medium))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            }
        }
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
