//
//  DummyTokenView.swift
//  Tub
//
//  Created by Henry on 11/11/24.
//

import SwiftUI

struct LoadingTokenView: View {
    var body: some View {
        
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    LoadingBox(width: 90, height: 90)
                    VStack(alignment: .leading) {
                        LoadingBox(width: 100, height: 20)
                        
                        LoadingBox(width: 200, height: 40)
                        
                        LoadingBox(width: 160, height: 14)
                    }
                    .padding(.bottom, 30)
                }
                
                // Chart
                LoadingBox(height: 300)
                
                Spacer()
                
                LoadingBox(height: 160)
                    .padding(.bottom, 2)
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity)
            .foregroundColor(AppColors.white)
        }
    }
}



