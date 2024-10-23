//
//  AccountBalance.swift
//  Tub
//
//  Created by Henry on 10/23/24.
//

import SwiftUI

struct AccountBalanceView: View {
    @ObservedObject var userModel: UserModel
    @ObservedObject var currentTokenModel: TokenModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Account Balance")
                .font(.sfRounded(size: .sm, weight: .bold))
                .opacity(0.7)
                .kerning(-1)
            
        //    let tokenValue = currentTokenModel.balanceLamps * (currentTokenModel.prices.last?.price ?? 0) / Int(1e9)
            let tokenValue = 0
            Text("\(PriceFormatter.formatPrice(lamports: userModel.balanceLamps + tokenValue)) ")
                .font(.sfRounded(size: .xl3))
                .fontWeight(.bold)
            
            let adjustedChange = userModel.balanceChangeLamps + tokenValue

            HStack {
                Text("\(PriceFormatter.formatPrice(lamports: adjustedChange, showSign: true, maxDecimals: 2))")
                
                let adjustedPercentage = userModel.initialBalanceLamps != 0  ? 100 - (Double(userModel.balanceLamps) / Double(userModel.initialBalanceLamps)) * 100 : 100;
                Text("(\(abs(adjustedPercentage), specifier: "%.1f")%)")
                
                // Format time elapsed
                Text("\(formatTimeElapsed(userModel.timeElapsed))")
                    .foregroundColor(.gray)
            }
            .font(.sfRounded(size: .sm, weight: .semibold))
            .foregroundColor(adjustedChange >= 0 ? .green : .red)
        }
        .padding()
    }
    
    private func formatTimeElapsed(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60

        if hours > 1 {
            return "past \(hours) hours"
        } else if hours > 0 {
            return "past hour"
        } else if minutes > 1 {
            return "past \(minutes) minutes"
        } else  {
            return "past minute"
        }
    }
}

