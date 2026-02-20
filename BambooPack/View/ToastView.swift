import SwiftUI

struct ToastView: View {
    @Binding var isShowing: Bool
    var message: String
    var duration: TimeInterval = 2.0
    
    var body: some View {
        if isShowing {
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                .padding(.bottom, 30) // Float slightly above the bottom
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isShowing = false
                        }
                    }
                }
            }
            .allowsHitTesting(false) // Never block touches
        }
    }
}

// Helper Extension to easily slap it on any View
extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        ZStack {
            self
            ToastView(isShowing: isShowing, message: message)
        }
    }
}
