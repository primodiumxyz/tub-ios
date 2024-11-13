import SwiftUI

struct NotificationBanner: View {
    let message: String
    let type: BannerType
    @Binding var isPresented: Bool
    
    enum BannerType {
        case success
        case error
        
        var backgroundColor: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(.white)
                Text(message)
                    .foregroundColor(.white)
                    .font(.sfRounded(size: .sm, weight: .medium))
                Spacer()
            }
            .padding()
            .background(type.backgroundColor)
            .cornerRadius(12)
            .padding(.horizontal)
            .onTapGesture {
                withAnimation {
                    isPresented = false
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if isPresented { // Only dismiss if still presented
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
    }
}
