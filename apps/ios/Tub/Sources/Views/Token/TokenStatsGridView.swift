//
//  TokenStatsGridView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//

import SwiftUI
import Combine

struct TokenStatsGridView: View {
    let stats: [(String, String)]
    
    var body: some View {
        ForEach(0..<stats.count/2, id: \.self) { index in
            HStack(alignment: .top, spacing: 20) {
                ForEach(0..<2) { subIndex in
                    let stat = stats[index * 2 + subIndex]
                    VStack {
                        HStack(alignment: .center) {
                            Text(stat.0)
                                .font(.sfRounded(size: .sm, weight: .regular))
                                .foregroundColor(AppColors.gray)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            Text(stat.1)
                                .font(.sfRounded(size: .base, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .topTrailing)
                                .foregroundColor(AppColors.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(height: 0.5)
                            .background(AppColors.gray.opacity(0.5))
                    }
                }
            }
            .padding(.top, 8)
        }
    }
} 
