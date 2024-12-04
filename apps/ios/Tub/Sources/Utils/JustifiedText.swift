//
//  TokenInfoCardView.swift
//  Tub
//
//  Created by yixintan on 12/4/24.

import SwiftUI

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
