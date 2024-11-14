import SwiftUI

struct OTPInputView: View {
    @FocusState private var pinFocusState: FocusPin? 
    @State private var pinOne = ""
    @State private var pinTwo = ""
    @State private var pinThree = ""
    @State private var pinFour = ""
    @State private var pinFive = ""
    @State private var pinSix = ""
    let onComplete: (String) -> Void
    
    private func handlePaste(_ pastedText: String, for pin: Binding<String>) {
        let cleaned = pastedText.filter { $0.isNumber }
        if cleaned.count == 6 {
            let chars = Array(cleaned)
            pinOne = String(chars[0])
            pinTwo = String(chars[1])
            pinThree = String(chars[2])
            pinFour = String(chars[3])
            pinFive = String(chars[4])
            pinSix = String(chars[5])
            onComplete(cleaned)
        }
    }
    
    private var otpCode : String {
        pinOne + pinTwo + pinThree + pinFour + pinFive + pinSix
    }


    var body: some View {
        HStack(spacing: 15) {
            TextField("", text: $pinOne)
                .tint(.white)
                .allowsHitTesting(false)
                .modifier(OtpModifer(pin: $pinOne, isFocused: pinFocusState == .pinOne))
                .onChange(of: pinOne) { oldVal, newVal in
                    if newVal.count > 1 {
                        handlePaste(newVal, for: $pinOne)
                    } else {
                        pinOne = newVal.filter { $0.isNumber }
                        if !pinOne.isEmpty {
                            pinFocusState = .pinTwo
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinOne)
                
            
            TextField("", text: $pinTwo)
                .tint(.white)
                .modifier(OtpModifer(pin: $pinTwo, isFocused: pinFocusState == .pinTwo))
                .allowsHitTesting(false)
                .onChange(of: pinTwo) { oldVal, newVal in
                    if newVal.count == 1 {
                        pinTwo = newVal.filter { $0.isNumber }
                        if !pinTwo.isEmpty {
                            pinFocusState = .pinThree
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinTwo)
                .onKeyPress(.delete, action: {
                    pinOne = ""
                    pinFocusState = .pinOne
                    return .handled
                })
            
            TextField("", text: $pinThree)
                .tint(.white)
                .modifier(OtpModifer(pin: $pinThree, isFocused: pinFocusState == .pinThree))
                .allowsHitTesting(false)
                .onChange(of: pinThree) { oldVal, newVal in
                    if newVal.count == 1 {
                        pinThree = newVal.filter { $0.isNumber }
                        if !pinThree.isEmpty {
                            pinFocusState = .pinFour
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinThree)
                .onKeyPress(.delete, action: {
                    pinTwo = ""
                    pinFocusState = .pinTwo
                    return .handled
                })
            
            TextField("", text: $pinFour)
                .tint(.white)
                .modifier(OtpModifer(pin: $pinFour, isFocused: pinFocusState == .pinFour))
                .allowsHitTesting(false)
                .onChange(of: pinFour) { oldVal, newVal in
                    if newVal.count == 1 {
                        pinFour = newVal.filter { $0.isNumber }
                        if !pinFour.isEmpty {
                            pinFocusState = .pinFive
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinFour)
                .onKeyPress(.delete, action: {
                    pinThree = ""
                    pinFocusState = .pinThree
                    return .handled
                })
            
            TextField("", text: $pinFive)
                .tint(.white)
                .modifier(OtpModifer(pin: $pinFive, isFocused: pinFocusState == .pinFive))
                .allowsHitTesting(false)
                .onChange(of: pinFive) { oldVal, newVal in
                    if newVal.count == 1 {
                        pinFive = newVal.filter { $0.isNumber }
                        if !pinFive.isEmpty {
                            pinFocusState = .pinSix
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinFive)
                .onKeyPress(.delete, action: {
                    pinFour = ""
                    pinFocusState = .pinFour
                    return .handled
                })
            
            TextField("", text: $pinSix)
                .tint(.white)
                .modifier(OtpModifer(pin: $pinSix, isFocused: pinFocusState == .pinSix))
                .allowsHitTesting(false)
                .onChange(of: pinSix) { oldVal, newVal in
                    if newVal.count == 1 {
                        pinSix = newVal.filter { $0.isNumber }
                        if !pinSix.isEmpty {
                            if otpCode.count != 6 || otpCode.contains(" ") { return }
                            else { onComplete(otpCode)}
                        }
                    }
                }
                .focused($pinFocusState, equals: .pinSix)
                .onKeyPress(.delete, action: {
                    if pinSix != "" {
                        pinSix = ""
                    } else {
                        pinFive = ""
                        pinFocusState = .pinFive
                    }
                    return .handled
                })
        }
        .onAppear(perform: {
            pinFocusState = .pinOne
            })
        .foregroundColor(.black)
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .padding(.horizontal)
    }
}

#Preview {
    OTPInputView(onComplete: { _ in })
}
