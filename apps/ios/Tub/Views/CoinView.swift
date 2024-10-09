//
//  ExploreView.swift
//  Tub
//
//  Created by Emerson Hsieh on 2024/9/26.
//

import SwiftUI
import Combine






struct TokenView : View {
    @ObservedObject var tokenModel: BaseTokenModel
    @EnvironmentObject private var userModel: UserModel
    init(tokenModel: BaseTokenModel) {
        self.tokenModel = tokenModel
    }
    
    var body: some View {
       VStack () {
        VStack (alignment: .leading) {
            HStack {
                Image(systemName: "bittokensign.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10)) // This will round the corners

                VStack(alignment: .leading){
                    Text("$\(tokenModel.token.symbol) (\(tokenModel.token.name))") // Update this line
                        .font(.sfRounded(size: .base, weight: .bold))
                    Text("\(tokenModel.prices.last?.price ?? 0, specifier: "%.3f") SOL")
                        .font(.sfRounded(size: .xl3, weight: .bold))


                }.foregroundColor(Color(red: 1, green: 0.92, blue: 0.52))
            }
            
            ChartView(prices: tokenModel.prices)
            VStack(alignment: .leading) {
               Text("Your \(tokenModel.token.symbol.uppercased()) Balance") // Update this line
                .font(.sfRounded(size: .sm, weight: .bold))
                    .opacity(0.7)
                    .kerning(-1)
                
               Text("\(tokenModel.tokenBalance, specifier: "%.3f") \(tokenModel.token.symbol.uppercased())") // Update this line
                    .font(.sfRounded(size: .xl2, weight: .bold))
           }
           
           BuySellForm(tokenModel: tokenModel)
         
        }.padding(8)
       }
       .frame(maxWidth: .infinity) // Add this line
       .background(.black)
       .foregroundColor(.white)
    }
}


#Preview {
    TokenView(tokenModel: MockTokenModel())
}
