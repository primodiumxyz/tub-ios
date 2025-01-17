//
//  ButtonStyles.swift
//  Tub
//
//  Created by JJ on 11/20/24.
//

import SwiftUI

struct PrimaryButton: View {
    var text: String
    var textColor: Color
    var backgroundColor: Color
    var strokeColor: Color? = nil
    var maxWidth: CGFloat? = nil
    var action: () -> Void
    var disabled: Bool = false
    var loading: Bool = false

    init(
        text: String,
        textColor: Color = .tubTextInverted,
        backgroundColor: Color = .tubBuyPrimary,
        strokeColor: Color? = nil,
        maxWidth: CGFloat? = .infinity,
        disabled: Bool = false,
        loading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.maxWidth = maxWidth
        self.action = action
        self.disabled = disabled
        self.loading = loading
    }

    var body: some View {
        ContentButton(
            backgroundColor: backgroundColor,
            strokeColor: strokeColor,
            maxWidth: maxWidth,
            disabled: disabled,
            loading: loading,
            action: action
        ) {
            Text(text)
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
        }
    }
}

struct OutlineButton: View {
    var text: String
    var textColor: Color
    var strokeColor: Color
    var backgroundColor: Color
    var maxWidth: CGFloat = 50
    var disabled: Bool = false
    var loading: Bool = false
    var action: () -> Void

    var body: some View {
        ContentButton(
            backgroundColor: backgroundColor,
            strokeColor: strokeColor,
            maxWidth: maxWidth,
            disabled: disabled,
            loading: loading,
            action: action
        ) {
            Text(text)
                .font(.sfRounded(size: .xl, weight: .semibold))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Circle Button Style - Eg. Add Funds button in AccountView
struct CircleButtonStyle: ButtonStyle {
    var icon: String
    var isSystemIcon: Bool
    var color: Color
    var size: CGFloat = 50
    var iconSize: CGFloat = 24
    var iconWeight: Font.Weight = .regular
    var disabled = false

    func makeBody(configuration: Self.Configuration) -> some View {
        ZStack {

            if isSystemIcon {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: iconSize, weight: iconWeight))
            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
        }
        .opacity(configuration.isPressed || disabled ? 0.5 : 1.0)
        .scaleEffect(configuration.isPressed && !disabled ? 0.95 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CircleButton: View {
    var icon: String
    var isSystemIcon: Bool = true 
    var color: Color
    var size: CGFloat = 50
    var iconSize: CGFloat = 24
    var iconWeight: Font.Weight = .regular
    var disabled = false
    var action: () -> Void

    var body: some View {
        Button(action: disabled ? {} : action) {
            EmptyView()
        }
        .buttonStyle(
            CircleButtonStyle(
                icon: icon,
                isSystemIcon: isSystemIcon,
                color: color,
                size: size,
                iconSize: iconSize,
                iconWeight: iconWeight,
                disabled: disabled
            )
        )
    }
}

// MARK: - Capsule Button Style - Eg. Capsule button in BuyForm
struct CapsuleButtonStyle: ButtonStyle {
    var text: String
    var textColor: Color
    var backgroundColor: Color
    var borderColor: Color?
    var borderWidth: CGFloat = 1
    var font: Font = .sfRounded(size: .base, weight: .bold)
    var disabled = false

    func makeBody(configuration: Self.Configuration) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(backgroundColor.opacity(configuration.isPressed ? 0.1 : 1))
            .clipShape(Capsule())
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        Capsule()
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
    }
}

struct CapsuleButton: View {
    var text: String
    var textColor: Color = .tubText
    var backgroundColor: Color = .tubText.opacity(0.15)
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1
    var font: Font = .sfRounded(size: .base, weight: .bold)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            CapsuleButtonStyle(
                text: text,
                textColor: textColor,
                backgroundColor: backgroundColor,
                borderColor: borderColor,
                borderWidth: borderWidth,
                font: font
            )
        )
    }
}

// MARK: - Icon Text Button Style - Eg. Logout button in AccountView
struct IconTextButtonStyle: ButtonStyle {
    var icon: String
    var isSystemIcon: Bool = true
    var text: String
    var textColor: Color
    var iconSize: CGSize = CGSize(width: 22, height: 22)
    var spacing: CGFloat = 16
    var bottomPadding: CGFloat = 40
    var font: Font = .sfRounded(size: .lg, weight: .medium)

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(spacing: spacing) {
            if isSystemIcon {
                Image(systemName: icon)
                    .resizable()
                    .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
                    .foregroundStyle(textColor)
                    .padding(.bottom, bottomPadding)
                    .padding(.leading, 4)
                    .padding(.trailing, 2)
            }else{
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize.width, height: iconSize.height, alignment: .center)
                    .foregroundStyle(textColor)
                    .padding(.bottom, bottomPadding)
                    .padding(.leading, 4)
                    .padding(.trailing, 2)
            }

            Text(text)
                .font(font)
                .foregroundStyle(textColor)
                .padding(.bottom, bottomPadding)
        }
        .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct IconTextButton: View {
    var icon: String
    var isSystemIcon: Bool = true
    var text: String
    var textColor: Color
    var iconSize: CGSize = CGSize(width: 22, height: 22)
    var spacing: CGFloat = 16
    var bottomPadding: CGFloat = 40
    var font: Font = .sfRounded(size: .lg, weight: .medium)
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            IconTextButtonStyle(
                icon: icon,
                isSystemIcon: isSystemIcon,
                text: text,
                textColor: textColor,
                iconSize: iconSize,
                spacing: spacing,
                bottomPadding: bottomPadding,
                font: font
            )
        )
    }
}

// MARK: - Icon Button Style - Eg. Copy to clipboard button in AccountDetailsView
struct IconButtonStyle: ButtonStyle {
    var icon: String
    var color: Color
    var size: CGFloat = 24

    func makeBody(configuration: Self.Configuration) -> some View {
        Image(systemName: icon)
            .foregroundStyle(color)
            .font(.system(size: size))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct IconButton: View {
    var icon: String
    var color: Color
    var size: CGFloat = 24
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            IconButtonStyle(
                icon: icon,
                color: color,
                size: size
            )
        )
    }
}

// MARK: - Outline Button with Icon Style - Eg. Google Sign In button in RegisterView
struct OutlineButtonWithIcon: View {
    var text: String
    var textColor: Color
    var strokeColor: Color
    var backgroundColor: Color
    var leadingView: AnyView? = nil
    var maxWidth: CGFloat = .infinity
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 8) {
                if let leadingView = leadingView {
                    leadingView
                        .frame(width: 20, height: 20)
                }
                Text(text)
                    .font(.sfRounded(size: .lg, weight: .semibold))
            }
            .frame(maxWidth: maxWidth, alignment: .center)
            .padding(10)
            .padding(.vertical, 5.0)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .inset(by: 0.5)
                    .stroke(strokeColor, lineWidth: 1)
                    .clipShape(Rectangle())
            )
        }
    }
}

// MARK: - Simple filter button style - Eg. Filter button in HistoryView
struct FilterButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.sfRounded(size: .sm, weight: .regular))
            .padding(.horizontal)
            .padding(.vertical, 6)
            .fixedSize(horizontal: true, vertical: false)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.tubNeutral, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct FilterButton: View {
    var text: String

    var body: some View {
        Button(action: {}) {
            Text(text)
        }
        .buttonStyle(FilterButtonStyle())
    }
}

// MARK: - Interval Button Style - Eg. Time interval selector in TokenView
struct IntervalButtonStyle: ButtonStyle {
    var text: String
    var isSelected: Bool
    var isLive: Bool
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Self.Configuration) -> some View {
        HStack(spacing: 8) {
            if isLive {
                Circle()
                    .fill(Color.red)
                    .frame(width: 7, height: 7)
            }
            Text(text)
                .font(.sfRounded(size: .sm, weight: .medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(width: 65)
        .background(isSelected ? colorScheme == .dark ? .tubBuyPrimary : .tubBuySecondary : .clear)
        .foregroundStyle(isSelected ? .black : .secondary)
        .cornerRadius(20)
        .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct IntervalButton: View {
    var timespan: Timespan
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            IntervalButtonStyle(
                text: timespan.rawValue,
                isSelected: isSelected,
                isLive: timespan == .live
            )
        )
    }
}

// MARK: - Content Button Style - Generic button that accepts any content
struct ContentButtonStyle<Content: View>: ButtonStyle {
    let content: Content
    var backgroundColor: Color
    var strokeColor: Color?
    var maxWidth: CGFloat?
    var disabled: Bool
    var loading: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        // Wrap the content in another view to extend the tap area
        ZStack {
            ProgressView().opacity(loading ? 1 : 0)
            content.opacity(loading ? 0 : 1)
        }
        .frame(maxWidth: maxWidth)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .opacity(disabled || loading ? 0.5 : 1.0)
        .background(backgroundColor.opacity(configuration.isPressed || disabled || loading ? 0.5 : 1.0))
        .cornerRadius(30)
        .overlay(
            Group {
                if let strokeColor = strokeColor {
                    RoundedRectangle(cornerRadius: 30)
                        .inset(by: 0.5)
                        .stroke(strokeColor, lineWidth: 1)
                }
            }
        )
        .contentShape(Rectangle())
        .scaleEffect(!disabled && !loading && configuration.isPressed ? 0.95 : 1)
        .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ContentButton<Content: View>: View {
    let content: Content
    var backgroundColor: Color
    var strokeColor: Color? = nil
    var maxWidth: CGFloat? = nil
    var action: () -> Void
    var disabled: Bool = false
    var loading: Bool = false

    init(
        backgroundColor: Color = .tubBuyPrimary,
        strokeColor: Color? = nil,
        maxWidth: CGFloat? = .infinity,
        disabled: Bool = false,
        loading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.maxWidth = maxWidth
        self.action = action
        self.disabled = disabled
        self.loading = loading
    }

    var body: some View {
        Button(action: self.disabled || self.loading ? {} : action) {
            EmptyView()
        }
        .buttonStyle(
            ContentButtonStyle(
                content: content,
                backgroundColor: backgroundColor,
                strokeColor: strokeColor,
                maxWidth: maxWidth,
                disabled: disabled,
                loading: loading
            )
        )
    }
}

// MARK: - Pill Image Button - For interactive buttons
struct PillImageButton: View {
    var icon: String
    var isSystemIcon: Bool = true
    var color: Color
    var iconSize: CGFloat = 24
    var horizontalPadding: CGFloat = 24
    var text: String
    var backgroundColor: Color = .clear
    var strokeColor: Color = .clear
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSystemIcon {
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.system(size: iconSize))
                } else {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: iconSize, height: iconSize)
                }
                
                Text(text)
                    .font(.sfRounded(size: .base, weight: .semibold))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(strokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Pill Image Label - For non-interactive styling Eg. Share button in ShareView
struct PillImageLabel: View {
    var icon: String
    var isSystemIcon: Bool = true
    var color: Color
    var iconSize: CGFloat = 24
    var horizontalPadding: CGFloat = 24
    var text: String
    var backgroundColor: Color = .clear
    var strokeColor: Color = .clear
    
    var body: some View {
        HStack(spacing: 8) {
            if isSystemIcon {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: iconSize))
            } else {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
            }
            
            Text(text)
                .font(.sfRounded(size: .base, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}
