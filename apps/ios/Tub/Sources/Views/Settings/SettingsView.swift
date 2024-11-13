//
//  SettingsView.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/12.
//

import SwiftUI
import Foundation

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .frame(width: 50, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(configuration.isOn ? AppColors.aquaGreen : AppColors.primaryPink, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(
                            EllipticalGradient(
                                stops: configuration.isOn ?
                                    [
                                        .init(color: Color(red: 0, green: 0.32, blue: 0.27).opacity(0.79), location: 0.00),
                                        .init(color: Color(red: 0.01, green: 1, blue: 0.85), location: 0.90)
                                    ] :
                                    [
                                        .init(color: Color(red: 0.64, green: 0.19, blue: 0.45).opacity(0.48), location: 0.00),
                                        .init(color: Color(red: 0.87, green: 0.26, blue: 0.61), location: 0.90)
                                    ],
                                center: UnitPoint(x: 0.5, y: 0.5)
                            )
                        )
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 10 : -10)
                )
                .animation(.spring(duration: 0.2), value: configuration.isOn)
                .onTapGesture {
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var defaultBuyValue: Double = 10.00
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 24) {
                    // Default Buy Value
                    DetailRow(
                        title: "Set Default Buy Value",
                        value: String(format: "$%.2f", defaultBuyValue)
                    )
                    
                    // Commented out for now
                    // Push Notifications Toggle
//                    DetailRow(
//                        title: "Push Notifications",
//                        value: ""
//                    ) {
//                        Toggle("", isOn: $pushNotificationsEnabled)
//                            .toggleStyle(CustomToggleStyle())
//                    }
                    
                    // Vibration Toggle
                    DetailRow(
                        title: "Vibration",
                        value: ""
                    ) {
                        Toggle("", isOn: $settingsManager.isVibrationEnabled)
                            .toggleStyle(CustomToggleStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                Spacer()
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppColors.aquaGreen)
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .foregroundColor(AppColors.white)
                }
            }
            .background(AppColors.black)
        }
    }
}

#Preview {
    SettingsView()
} 
