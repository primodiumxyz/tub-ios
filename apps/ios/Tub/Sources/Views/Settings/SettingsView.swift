//
//  SettingsView.swift
//  Tub
//
//  Created by Yi Xin Tan on 2024/11/12.
//

import Foundation
import SwiftUI

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
                .frame(width: 50, height: 30)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(configuration.isOn ? .tubSellPrimary : .tubBuyPrimary, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(
                            configuration.isOn
                                ? Gradients.toggleOnGradient
                                : Gradients.toggleOffGradient
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
    @EnvironmentObject var priceModel : SolPriceModel

    // Add temporary state for editing
    @State private var tempDefaultValueUsd: String = ""
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
            get: { priceModel.usdcToUsd(usdc: settingsManager.defaultBuyValueUsdc) },
            set: { newValue in
                // Round to 2 decimal places
                let rounded = (newValue * 100).rounded() / 100
                settingsManager.defaultBuyValueUsdc = priceModel.usdToUsdc(usd: max(0, rounded))
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 24) {
                    DetailRow(
                        title: "Default Buy Value",
                        value: ""
                    ) {
                        HStack(spacing: 4) {
                            Text("$")
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .foregroundStyle(.tubNeutral)
                            TextField("", text: $tempDefaultValueUsd)
                                .focused($isEditing)
                                .keyboardType(.decimalPad)
                                .font(.sfRounded(size: .lg, weight: .semibold))
                                .multilineTextAlignment(.trailing)
                                .foregroundStyle(.primary)
                                .frame(width: textWidth(for: tempDefaultValueUsd))
                                .onChange(of: tempDefaultValueUsd) { _, newValue in
                                    // Remove any non-numeric characters except decimal point
                                    let filtered = newValue.filter { "0123456789.".contains($0) }

                                    // Ensure only one decimal point
                                    let components = filtered.components(separatedBy: ".")
                                    if components.count > 2 {
                                        tempDefaultValueUsd = components[0] + "." + components[1]
                                    }
                                    else if components.count == 2 {
                                        // Limit to 2 decimal places
                                        let decimals = components[1].prefix(2)
                                        tempDefaultValueUsd = components[0] + "." + String(decimals)
                                    }
                                    else {
                                        tempDefaultValueUsd = filtered
                                    }
                                }
                                .onAppear {
                                    tempDefaultValueUsd = String(format: "%.2f", validatedDefaultBuyValue.wrappedValue)
                                }
                                .onSubmit {
                                    if let newValue = Double(tempDefaultValueUsd) {
                                        validatedDefaultBuyValue.wrappedValue = newValue
                                    }
                                }
                            Image(systemName: "pencil")
                                .foregroundStyle(.tubBuyPrimary)
                                .font(.system(size: 20))
                        }
                    }

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

                Text(serverBaseUrl).foregroundStyle(.tubText)
                    .font(.caption)
                    .opacity(0.5)
                Spacer()
            }
            .navigationBarBackButtonHidden(false)
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Keep keyboard toolbar
                ToolbarItem(placement: .keyboard) {
                    Button("Save") {
                        isEditing = false
                        if let newValue = Double(tempDefaultValueUsd) {
                            validatedDefaultBuyValue.wrappedValue = newValue
                        }
                    }
                    .foregroundStyle(.tubSellPrimary)
                    .font(.system(size: 20))
                }
            }
            .background(Color(UIColor.systemBackground))
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
        .preferredColorScheme(.dark)
}
