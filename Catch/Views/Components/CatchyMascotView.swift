import SwiftUI

/// Catchy the Baby Elephant - The memory companion for ADHD minds.
/// "An elephant never forgets — so your brain doesn't have to carry it all."
public struct CatchyMascotView: View {
    public enum Pose {
        case mini        // For header / navigation (24-36pt)
        case standard    // Card / Widget (48-72pt)
        case emptyState  // Main view placeholder (80-140pt)
        case celebrating // Trunk raised with sparkles / toast
    }

    var pose: Pose
    var size: CGFloat
    var animated: Bool

    @State private var isWiggling: Bool = false
    @State private var isGleaming: Bool = false
    @State private var bounceOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0

    // Static cached image so decoding is instant
    private static var cachedImage: UIImage? = {
        if let path = Bundle.main.path(forResource: "CatchyLogo", ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        let fallbackPaths = [
            "/Users/harshmathur/Projects/Catch/Catch/Resources/CatchyLogo.png",
            "/Users/harshmathur/Projects/Catch/Catch/Resources/CatchyIcon.png"
        ]
        for p in fallbackPaths {
            if let img = UIImage(contentsOfFile: p) {
                return img
            }
        }
        return UIImage(named: "CatchyLogo")
    }()

    public init(pose: Pose = .standard, size: CGFloat = 40, animated: Bool = true) {
        self.pose = pose
        self.size = size
        self.animated = animated
    }

    public var body: some View {
        ZStack {
            // Soft background aura for emptyState and celebrating
            if pose == .emptyState || pose == .celebrating {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.85, green: 0.92, blue: 1.0).opacity(0.45),
                                Color(red: 0.95, green: 0.96, blue: 1.0).opacity(0.15),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: size * 0.75
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(isGleaming ? 1.06 : 0.96)
            }

            if let image = Self.cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(rotationAngle))
            } else {
                // High-fidelity fallback
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(Theme.brandTint)
            }
        }
        .offset(y: bounceOffset)
        .onAppear {
            if animated && (pose == .emptyState || pose == .celebrating) {
                withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    isGleaming = true
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard animated else { return }
            HapticsManager.shared.light()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                bounceOffset = -6
                rotationAngle = -4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    bounceOffset = 0
                    rotationAngle = 0
                }
            }
        }
    }
}
