import SwiftUI

/// Catchy the Baby Elephant - The memory companion for ADHD minds.
/// "An elephant never forgets — so your brain doesn't have to carry it all."
public struct CatchyMascotView: View {
    public enum Pose {
        case mini        // For header / navigation (24-36pt)
        case standard    // Card / Widget (48-72pt)
        case emptyState  // Main view placeholder (120-160pt)
        case celebrating // Trunk raised with sparkles
    }

    var pose: Pose
    var size: CGFloat
    var animated: Bool
    
    @State private var isWiggling: Bool = false
    @State private var isGleaming: Bool = false
    @State private var bounceOffset: CGFloat = 0

    public init(pose: Pose = .standard, size: CGFloat = 40, animated: Bool = true) {
        self.pose = pose
        self.size = size
        self.animated = animated
    }

    public var body: some View {
        ZStack {
            if let image = loadCatchyImage() {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.12), radius: size * 0.08, x: 0, y: size * 0.04)
            } else {
                vectorCatchy
                    .frame(width: size, height: size)
            }
        }
        .offset(y: bounceOffset)
        .onAppear {
            if animated {
                withAnimation(Animation.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    isGleaming = true
                }
            }
        }
        .onTapGesture {
            guard animated else { return }
            HapticsManager.shared.light()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5, blendDuration: 0)) {
                bounceOffset = -8
                isWiggling = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    bounceOffset = 0
                    isWiggling = false
                }
            }
        }
    }

    // MARK: - Image Loader
    private func loadCatchyImage() -> UIImage? {
        if let path = Bundle.main.path(forResource: "CatchyMascot", ofType: "jpg"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        return UIImage(named: "CatchyMascot")
    }

    // MARK: - Pure SwiftUI Vector Mascot
    private var vectorCatchy: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Soft background aura for emptyState / celebrating
                if pose == .emptyState || pose == .celebrating {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.25), Color.blue.opacity(0.08), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: w * 0.6
                            )
                        )
                        .scaleEffect(isGleaming ? 1.08 : 0.95)
                }

                // Left Outer & Inner Ear
                ZStack {
                    Ellipse()
                        .fill(Color(red: 0.56, green: 0.68, blue: 0.98))
                        .frame(width: w * 0.38, height: h * 0.46)
                    Ellipse()
                        .fill(Color(red: 0.98, green: 0.74, blue: 0.82))
                        .frame(width: w * 0.24, height: h * 0.32)
                }
                .rotationEffect(.degrees(isWiggling ? -22 : -14))
                .offset(x: -w * 0.28, y: -h * 0.08)

                // Right Outer & Inner Ear
                ZStack {
                    Ellipse()
                        .fill(Color(red: 0.56, green: 0.68, blue: 0.98))
                        .frame(width: w * 0.38, height: h * 0.46)
                    Ellipse()
                        .fill(Color(red: 0.98, green: 0.74, blue: 0.82))
                        .frame(width: w * 0.24, height: h * 0.32)
                }
                .rotationEffect(.degrees(isWiggling ? 22 : 14))
                .offset(x: w * 0.28, y: -h * 0.08)

                // Elephant Head
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.66, green: 0.76, blue: 0.99), Color(red: 0.52, green: 0.64, blue: 0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: w * 0.68, height: h * 0.68)
                    .offset(y: -h * 0.04)

                // Rosy Cheeks
                HStack(spacing: w * 0.34) {
                    Circle()
                        .fill(Color(red: 0.99, green: 0.62, blue: 0.72).opacity(0.85))
                        .frame(width: w * 0.12, height: w * 0.12)
                    Circle()
                        .fill(Color(red: 0.99, green: 0.62, blue: 0.72).opacity(0.85))
                        .frame(width: w * 0.12, height: w * 0.12)
                }
                .offset(y: -h * 0.02)

                // Cute Expressive Eyes
                HStack(spacing: w * 0.20) {
                    // Left Eye
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.25))
                            .frame(width: w * 0.11, height: w * 0.11)
                        Circle()
                            .fill(Color.white)
                            .frame(width: w * 0.04, height: w * 0.04)
                            .offset(x: -w * 0.02, y: -w * 0.02)
                    }
                    // Right Eye
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.14, blue: 0.25))
                            .frame(width: w * 0.11, height: w * 0.11)
                        Circle()
                            .fill(Color.white)
                            .frame(width: w * 0.04, height: w * 0.04)
                            .offset(x: -w * 0.02, y: -w * 0.02)
                    }
                }
                .offset(y: -h * 0.10)

                // Trunk (Curling Upwards Catching the Thought)
                Path { path in
                    path.move(to: CGPoint(x: w * 0.50, y: h * 0.50))
                    path.addCurve(
                        to: CGPoint(x: w * 0.64, y: h * 0.28),
                        control1: CGPoint(x: w * 0.50, y: h * 0.64),
                        control2: CGPoint(x: w * 0.66, y: h * 0.50)
                    )
                }
                .stroke(
                    Color(red: 0.50, green: 0.62, blue: 0.94),
                    style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round)
                )

                // Glowing Golden Thought Star / Spark
                ZStack {
                    Image(systemName: "sparkle")
                        .font(.system(size: w * 0.22, weight: .bold))
                        .foregroundColor(Color.yellow.opacity(0.85))
                        .scaleEffect(isGleaming ? 1.25 : 0.95)
                        .rotationEffect(.degrees(isGleaming ? 20 : -10))
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: w * 0.14, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
                }
                .offset(x: w * 0.20, y: -h * 0.28)
            }
        }
    }
}
