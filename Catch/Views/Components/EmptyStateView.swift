import SwiftUI

/// Minimalist, calm empty state presentation.
public struct EmptyStateView: View {
    public let icon: String
    public let title: String
    public let subtitle: String

    public init(
        icon: String = "tray",
        title: String = "Your inbox is clear",
        subtitle: String = "Tap + to capture whatever is on your mind."
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Theme.tertiaryText)
                .padding(.bottom, 4)

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.primaryText)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
