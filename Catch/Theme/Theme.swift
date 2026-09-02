import SwiftUI

/// Design system tokens, colors, typography, and tactile animation presets for Catch.
/// Features a warm, cozy paper & bento aesthetic with Apple Liquid Glass compatibility.
public enum Theme {
    // MARK: - Colors (Adaptive Warm Paper & Cozy Canvas)
    public static var background: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.10, blue: 0.10, alpha: 1.0) // Deep warm espresso charcoal
                : UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0) // Warm eggshell / cozy paper canvas
        })
    }

    public static var secondaryBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.18, blue: 0.18, alpha: 1.0)
                : UIColor(red: 0.94, green: 0.92, blue: 0.89, alpha: 1.0) // Soft almond cream
        })
    }

    public static var tertiaryBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.25, green: 0.23, blue: 0.23, alpha: 1.0)
                : UIColor(red: 0.90, green: 0.88, blue: 0.84, alpha: 1.0)
        })
    }

    public static var cardBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.15, blue: 0.15, alpha: 1.0) // Elevated dark slate
                : UIColor.white // Crisp elevated white paper card
        })
    }

    // MARK: - Typography Colors
    public static var primaryText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.98, green: 0.97, blue: 0.96, alpha: 1.0)
                : UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1.0) // Rich dark espresso
        })
    }

    public static var secondaryText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.72, green: 0.69, blue: 0.67, alpha: 1.0)
                : UIColor(red: 0.48, green: 0.44, blue: 0.41, alpha: 1.0) // Warm slate coffee
        })
    }

    public static var tertiaryText: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.50, green: 0.47, blue: 0.45, alpha: 1.0)
                : UIColor(red: 0.65, green: 0.61, blue: 0.58, alpha: 1.0)
        })
    }

    // MARK: - Category Tints (Harmonious & Warm)
    public static let brandTint = Color(red: 0.38, green: 0.46, blue: 0.98) // Calm vibrant indigo
    public static let accentWarm = Color(red: 0.96, green: 0.65, blue: 0.14) // Amber / Note
    public static let accentSuccess = Color(red: 0.18, green: 0.76, blue: 0.50) // Mint Emerald / Task
    public static let accentExpense = Color(red: 0.95, green: 0.33, blue: 0.42) // Coral Rose / Expense

    public static var border: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 0.07) // Subtle paper rim
        })
    }

    public static let subtleShadow = Color.black.opacity(0.04)
    public static let tactileShadow = Color.black.opacity(0.06)

    // MARK: - Layout & Corner Radius
    public static let cornerRadiusSmall: CGFloat = 8
    public static let cornerRadiusMedium: CGFloat = 14
    public static let cornerRadiusLarge: CGFloat = 20
    public static let cornerRadiusPill: CGFloat = 100

    // MARK: - Animation Presets (Tuned for 120Hz ProMotion)
    public static let springQuick = Animation.spring(response: 0.28, dampingFraction: 0.72)
    public static let springSmooth = Animation.spring(response: 0.38, dampingFraction: 0.82)
    public static let springBouncy = Animation.spring(response: 0.34, dampingFraction: 0.62)
}

// MARK: - Tactile Press Button Style (Award-Winning Physical 3D Feel)
public struct TactilePressButtonStyle: ButtonStyle {
    public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light

    public init(hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        self.hapticStyle = hapticStyle
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .offset(y: configuration.isPressed ? 2.0 : 0)
            .animation(Theme.springQuick, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: hapticStyle).impactOccurred(intensity: 0.7)
                }
            }
    }
}

public extension ButtonStyle where Self == TactilePressButtonStyle {
    static var tactile: TactilePressButtonStyle { TactilePressButtonStyle() }
    static func tactile(haptic: UIImpactFeedbackGenerator.FeedbackStyle) -> TactilePressButtonStyle {
        TactilePressButtonStyle(hapticStyle: haptic)
    }
}

// MARK: - Tactile Paper Card Modifier
public struct CatchCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = Theme.cornerRadiusMedium

    public func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: Theme.subtleShadow, radius: 8, x: 0, y: 3)
            .shadow(color: Theme.tactileShadow, radius: 1, x: 0, y: 1)
    }
}

public extension View {
    func catchCard(cornerRadius: CGFloat = Theme.cornerRadiusMedium) -> some View {
        self.modifier(CatchCardModifier(cornerRadius: cornerRadius))
    }

    func staggeredEntrance(index: Int) -> some View {
        self.modifier(StaggeredEntranceModifier(index: index))
    }

    func fluidScrollTransition() -> some View {
        self.modifier(FluidScrollCardModifier())
    }
}

// MARK: - Staggered Scroll & Entrance Modifiers (Award-Winning Dynamics)
public struct StaggeredEntranceModifier: ViewModifier {
    public let index: Int
    @State private var isVisible: Bool = false

    public init(index: Int) {
        self.index = index
    }

    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                let delay = min(Double(index) * 0.04, 0.32)
                withAnimation(Theme.springSmooth.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

public struct FluidScrollCardModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .scrollTransition(.animated(Theme.springSmooth)) { view, phase in
                    view
                        .opacity(phase.isIdentity ? 1.0 : 0.72)
                        .scaleEffect(phase.isIdentity ? 1.0 : 0.96)
                        .offset(y: phase.isIdentity ? 0 : 12)
                }
        } else {
            content
        }
    }
}
