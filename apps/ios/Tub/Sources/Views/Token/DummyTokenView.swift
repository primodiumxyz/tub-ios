//
//  DummyTokenView.swift
//  Tub
//
//  Created by Henry on 11/11/24.
//

import SwiftUI

struct DummyTokenView: View {
    var body: some View {
        
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing : 4) {
                LoadingBox(width: 100, height: 30)
                
                LoadingBox(width: 200, height: 40)
                
                LoadingBox(width: 160, height: 14)
                    .padding(.bottom, 8)
                
                // Chart
                LoadingBox(height: 300)
                    .padding(.bottom, 18)
                
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



