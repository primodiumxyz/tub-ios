//
//  ButtonStyles.swift
//  Tub
//
//  Created by JJ on 11/20/24.
//

import SwiftUI

struct HubButtonStyle: ButtonStyle {
    var text: String
    var textColor: Color
    var backgroundColor: Color
    var strokeColor: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text(text)
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 300)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor.opacity(configuration.isPressed ? 0.5 : 1.0))
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 0.5)
                .stroke(strokeColor, lineWidth: 1)
        )
        .scaleEffect(configuration.isPressed ? 1.025 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct HubButton: View {
    var text: String
    var textColor: Color
    var backgroundColor: Color
    var strokeColor: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {}
            .buttonStyle(
                HubButtonStyle(
                    text: text,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    strokeColor: strokeColor
                )
            )
    }
}

struct HubButtonYellow: View {
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {}
            .buttonStyle(
                HubButtonStyle(
                    text: text,
                    textColor: .black,
                    backgroundColor: .yellow,
                    strokeColor: .black
                )
            )
    }
}

/////////////////////////////////////

struct ImageButtonStyle: ButtonStyle {
    var image: String
    var pressedImage: String
    var text: String

    func makeBody(configuration: Self.Configuration) -> some View {
        ZStack {
            Image(configuration.isPressed ? pressedImage : image)
                .resizable()
                .scaledToFit()
            Text(text)
                .font(.footnote)
        }
        .frame(width: 60, height: 60)
    }
}

struct ImageButton: View {
    var image: String
    var pressedImage: String
    var text: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {}
            .buttonStyle(
                ImageButtonStyle(
                    image: image,
                    pressedImage: pressedImage,
                    text: text
                )
            )
    }
}
