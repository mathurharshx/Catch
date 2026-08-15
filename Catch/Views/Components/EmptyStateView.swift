import SwiftUI

/// Minimalist, calm empty state presentation featuring Catchy the mascot.
public struct EmptyStateView: View {
    public let icon: String
    public let title: String
    public let subtitle: String
    public let showCatchy: Bool

    public init(
        icon: String = "tray",
        title: String = "Your mind is clear",
        subtitle: String = "Catchy is ready to remember whatever's on your mind.",
        showCatchy: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.showCatchy = showCatchy
    }

    public var body: some View {
        VStack(spacing: 14) {
            if showCatchy {
                CatchyMascotView(pose: .emptyState, size: 76, animated: true)
                    .padding(.bottom, 2)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Theme.tertiaryText)
                    .padding(.bottom, 4)
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.primaryText)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundColor(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
}
