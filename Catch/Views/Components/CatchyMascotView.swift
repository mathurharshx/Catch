import SwiftUI

/// Catchy the Baby Elephant - The ADHD Memory Companion & Mascot.
/// "An elephant never forgets — so your brain doesn't have to carry it all."
public struct CatchyMascotView: View {
    public enum Pose {
        case catching    // Catching glowing thought butterfly (Home Header / Command Deck)
        case noteTaker   // Holding checklist notepad & pencil (Settings / History / Tasks)
        case listening   // Wearing studio headphones & podcast mic (Voice Recording)
        case standard    // Classic sitting mascot with glasses
        case mini        // Mini compact header avatar
        case emptyState  // Floating with soothing radiant aura
        case celebrating // Joyful bounce with sparkles on item captured
    }

    public var pose: Pose
    public var size: CGFloat
    public var animated: Bool

    @State private var isGleaming: Bool = false
    @State private var bounceOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    @State private var scaleMultiplier: CGFloat = 1.0

    // Static image cache for instantaneous 60fps rendering without disk lag
    private static var imageCache: [String: UIImage] = [:]

    private static func getOrLoadImage(named name: String) -> UIImage? {
        if let cached = imageCache[name] {
            return cached
        }
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let img = UIImage(contentsOfFile: path) {
            imageCache[name] = img
            return img
        }
        let fallbackPaths = [
            "/Users/harshmathur/Projects/Catch/Catch/Resources/\(name).png",
            "/Users/harshmathur/Projects/Catch/Catch/Resources/CatchyLogo.png"
        ]
        for p in fallbackPaths {
            if let img = UIImage(contentsOfFile: p) {
                imageCache[name] = img
                return img
            }
        }
        let uiImg = UIImage(named: name) ?? UIImage(named: "CatchyLogo")
        if let uiImg = uiImg {
            imageCache[name] = uiImg
        }
        return uiImg
    }

    public init(pose: Pose = .catching, size: CGFloat = 40, animated: Bool = true) {
        self.pose = pose
        self.size = size
        self.animated = animated
    }

    private var assetNameForPose: String {
        switch pose {
        case .catching, .mini:
            return "CatchyCatching"
        case .noteTaker:
            return "CatchyNotepad"
        case .listening:
            return "CatchyListening"
        case .standard, .emptyState, .celebrating:
            return "CatchyCatching"
        }
    }

    public var body: some View {
        ZStack {
            // Radiant Aura for emptyState and celebrating
            if pose == .emptyState || pose == .celebrating {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.82, green: 0.90, blue: 1.0).opacity(0.45),
                                Color(red: 0.94, green: 0.96, blue: 1.0).opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: size * 0.75
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)
                    .scaleEffect(isGleaming ? 1.06 : 0.95)
            }

            if let image = Self.getOrLoadImage(named: assetNameForPose) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .scaleEffect(scaleMultiplier)
                    .rotationEffect(.degrees(rotationAngle))
            } else {
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
                bounceOffset = -7
                rotationAngle = -4
                scaleMultiplier = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    bounceOffset = 0
                    rotationAngle = 0
                    scaleMultiplier = 1.0
                }
            }
        }
    }
}
