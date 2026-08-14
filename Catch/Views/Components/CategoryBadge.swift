import SwiftUI

/// Compact visual pill representing a capture category.
public struct CategoryBadge: View {
    public let type: CaptureType
    public var isSelected: Bool = false
    public var showText: Bool = true

    public init(type: CaptureType, isSelected: Bool = false, showText: Bool = true) {
        self.type = type
        self.isSelected = isSelected
        self.showText = showText
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: isSelected ? type.filledIconName : type.iconName)
                .font(.system(size: 11, weight: .semibold))

            if showText {
                Text(type.displayName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .foregroundColor(isSelected ? .white : type.tintColor)
        .background(
            Capsule()
                .fill(isSelected ? type.tintColor : type.tintColor.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.clear : type.tintColor.opacity(0.25), lineWidth: 0.8)
        )
        .animation(Theme.springQuick, value: isSelected)
    }
}
