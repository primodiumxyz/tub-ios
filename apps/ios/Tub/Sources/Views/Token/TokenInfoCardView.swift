//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 10/11/24.
//
import SwiftUI

struct TokenInfoCardView: View {
    @ObservedObject var tokenModel: TokenModel
    @EnvironmentObject var priceModel: SolPriceModel
    @EnvironmentObject var userModel: UserModel
    var stats: [StatValue]
    @State private var isDescriptionExpanded = false

    var activeTab: String {
        let balance: Int = userModel.tokenBalanceLamps ?? 0
        return balance > 0 ? "sell" : "buy"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 0) {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 60, height: 3)
                    .background(.tubNeutral)
                    .cornerRadius(100)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 22, maxHeight: 22, alignment: .center)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(tokenModel.token.name)
                        .font(.sfRounded(size: .xl, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.bottom, 4)

                    ForEach(stats) { stat in
                        VStack(spacing: 10) {
                            HStack(alignment: .center) {
                                Text(stat.title)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: true, vertical: false)

                                Text(stat.value)
                                    .font(.sfRounded(size: .base, weight: .semibold))
                                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                                    .foregroundStyle(stat.color ?? .tubText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            //divider
                            Rectangle()
                                .foregroundStyle(.clear)
                                .frame(height: 0.5)
                                .background(Color.gray.opacity(0.5))
                        }
                        .padding(.vertical, 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.sfRounded(size: .xl, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .topLeading)

                        VStack(alignment: .leading, spacing: 8) {
                            if !tokenModel.token.description.isEmpty {
                                JustifiedText(text: tokenModel.token.description, isExpanded: $isDescriptionExpanded)
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundStyle(.secondary)

                                if tokenModel.token.description.count > 200 {
                                    Button(action: {
                                        withAnimation {
                                            isDescriptionExpanded.toggle()
                                        }
                                    }) {
                                        Text(isDescriptionExpanded ? "Show Less" : "Show More")
                                            .font(.sfRounded(size: .sm, weight: .medium))
                                            .foregroundStyle(.tubBuyPrimary)
                                    }
                                }
                            } else {
                                Text("This token is still writing its autobiography... 📝")
                                    .font(.sfRounded(size: .sm, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .scrollBounceBehavior(.basedOnSize, axes: [.vertical])
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .cornerRadius(20)
            }
        }
    }
}

struct JustifiedText: UIViewRepresentable {
    let text: String
    var font: UIFont?
    var textColor: UIColor?
    @Binding var isExpanded: Bool
    let maxLines: Int = 5
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = isExpanded ? 0 : maxLines
        label.textAlignment = .justified
        label.lineBreakMode = .byTruncatingTail
        label.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 40
        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.numberOfLines = isExpanded ? 0 : maxLines
        if let font = font {
            uiView.font = font
        }
        if let textColor = textColor {
            uiView.textColor = textColor
        }
    }
}

extension JustifiedText {
    func font(_ font: Font) -> JustifiedText {
        let uiFont = UIFont(
            descriptor: UIFontDescriptor(name: "SF Pro Rounded", size: 14),
            size: 14
        )
        return JustifiedText(text: self.text, font: uiFont, textColor: self.textColor, isExpanded: self._isExpanded)
    }
    
    func foregroundStyle(_ color: Color) -> JustifiedText {
        return JustifiedText(text: self.text, font: self.font, textColor: UIColor(color), isExpanded: self._isExpanded)
    }
}
