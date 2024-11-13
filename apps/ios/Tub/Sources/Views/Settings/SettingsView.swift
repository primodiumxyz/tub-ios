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
    @StateObject private var settingsManager = SettingsManager.shared
    // Add temporary state for editing
    @State private var tempDefaultValue: String = ""
    @FocusState private var isEditing: Bool
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.currencyCode = "USD"
        formatter.currencySymbol = "$"
        return formatter
    }()
    
    // Create a computed binding to handle validation
    private var validatedDefaultBuyValue: Binding<Double> {
        Binding(
            get: { settingsManager.defaultBuyValue },
            set: { newValue in
                // Round to 2 decimal places
                let rounded = (newValue * 100).rounded() / 100
                settingsManager.defaultBuyValue = max(0, rounded)
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 24) {
                    DetailRow(
                        title: "Set Default Buy Value",
                        value: ""
                    ) {
                        HStack(spacing: 4) {    
                            Text("$")
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .foregroundColor(AppColors.white.opacity(0.5))
                            TextField("", text: $tempDefaultValue)
                                .focused($isEditing)
                                .keyboardType(.decimalPad)
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(AppColors.white)
                                .frame(width: textWidth(for: tempDefaultValue))
                                .onChange(of: tempDefaultValue) { newValue in
                                    // Remove any non-numeric characters except decimal point
                                    let filtered = newValue.filter { "0123456789.".contains($0) }
                                    
                                    // Ensure only one decimal point
                                    let components = filtered.components(separatedBy: ".")
                                    if components.count > 2 {
                                        tempDefaultValue = components[0] + "." + components[1]
                                    } else if components.count == 2 {
                                        // Limit to 2 decimal places
                                        let decimals = components[1].prefix(2)
                                        tempDefaultValue = components[0] + "." + String(decimals)
                                    } else {
                                        tempDefaultValue = filtered
                                    }
                                }
                                .onAppear {
                                    tempDefaultValue = String(format: "%.2f", settingsManager.defaultBuyValue)
                                }
                                .onSubmit {
                                    updateDefaultValue()
                                }
                            Image(systemName: "pencil")
                                .foregroundColor(AppColors.white)
                                .font(.system(size: 20))
                        }
                    }
                    
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
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isEditing = false
                    updateDefaultValue()
                }
            }
        }
    }
    
    private func updateDefaultValue() {
        if let newValue = Double(tempDefaultValue) {
            let rounded = (newValue * 100).rounded() / 100
            settingsManager.defaultBuyValue = max(0, rounded)
        }
    }
    
    private func textWidth(for text: String) -> CGFloat {
        let font = UIFont.systemFont(ofSize: 17, weight: .semibold)  
        let attributes = [NSAttributedString.Key.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 10 
    }
}

#Preview {
    SettingsView()
} 
