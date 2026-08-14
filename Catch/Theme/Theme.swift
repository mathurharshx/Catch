import SwiftUI

/// Design system tokens, colors, typography, and animation presets for Catch.
public enum Theme {
    // MARK: - Colors
    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)

    public static let primaryText = Color.primary
    public static let secondaryText = Color.secondary
    public static let tertiaryText = Color(uiColor: .tertiaryLabel)

    public static let brandTint = Color(red: 0.38, green: 0.45, blue: 0.98) // Calm vibrant indigo
    public static let accentWarm = Color(red: 0.96, green: 0.65, blue: 0.14) // Amber
    public static let accentSuccess = Color(red: 0.20, green: 0.78, blue: 0.55) // Emerald
    public static let accentExpense = Color(red: 0.95, green: 0.33, blue: 0.42) // Rose/Coral

    public static let border = Color(uiColor: .separator).opacity(0.4)
    public static let subtleShadow = Color.black.opacity(0.06)

    // MARK: - Layout & Corner Radius
    public static let cornerRadiusSmall: CGFloat = 8
    public static let cornerRadiusMedium: CGFloat = 14
    public static let cornerRadiusLarge: CGFloat = 20
    public static let cornerRadiusPill: CGFloat = 100

    // MARK: - Animation
    public static let springQuick = Animation.spring(response: 0.3, dampingFraction: 0.75)
    public static let springSmooth = Animation.spring(response: 0.4, dampingFraction: 0.85)
    public static let springBouncy = Animation.spring(response: 0.35, dampingFraction: 0.65)
}

// MARK: - View Modifiers
public struct CatchCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = Theme.cornerRadiusMedium

    public func body(content: Content) -> some View {
        content
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border, lineWidth: 0.5)
            )
            .shadow(color: Theme.subtleShadow, radius: 4, x: 0, y: 2)
    }
}

public extension View {
    func catchCard(cornerRadius: CGFloat = Theme.cornerRadiusMedium) -> some View {
        self.modifier(CatchCardModifier(cornerRadius: cornerRadius))
    }
}
