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
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    LoadingBox(width: 50, height: 50)
                    VStack(alignment: .leading, spacing: 8) {
                        LoadingBox(width: 100, height: 16)
                        
                        LoadingBox(width: 200, height: 40).padding(.vertical, 4)
                        
                        LoadingBox(width: 160, height: 12)
                    }
                }
                .padding(.bottom, 30)

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


#Preview {
    LoadingTokenView().background(.black)
}

