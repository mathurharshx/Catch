import SwiftUI

/// Micro-launch splash screen featuring animated "Catchy" mascot.
public struct LaunchSplashView: View {
    public let onDismiss: () -> Void

    @State private var mascotScale: CGFloat = 1.0
    @State private var mascotOpacity: Double = 1.0
    @State private var textOpacity: Double = 1.0
    @State private var hasDismissed: Bool = false

    public init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                // Animated Catchy Mascot GIF
                GIFImageView(gifName: "CatchyLaunch.gif")
                    .frame(width: 220, height: 260)
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)

                // Catchy Branding Tagline
                Text("catchy")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Theme.primaryText)
                    .tracking(1.5)
                    .opacity(textOpacity)

                Spacer()

                // Subtle hint for user
                Text("tap anywhere to continue")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.tertiaryText)
                    .opacity(textOpacity * 0.7)
                    .padding(.bottom, 24)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissImmediately()
        }
        .onAppear {
            // Auto-dismiss smoothly after 1.4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                dismissImmediately()
            }
        }
    }

    private func dismissImmediately() {
        guard !hasDismissed else { return }
        hasDismissed = true
        HapticsManager.shared.light()
        withAnimation(.easeOut(duration: 0.3)) {
            mascotOpacity = 0.0
            textOpacity = 0.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            onDismiss()
        }
    }
}
