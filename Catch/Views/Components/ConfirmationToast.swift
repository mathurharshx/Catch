import SwiftUI

/// Satisfying instant confirmation toast ("✓ Saved to Notes")
public struct ConfirmationToast: View {
    public let message: String
    public let type: CaptureType

    public init(message: String, type: CaptureType) {
        self.message = message
        self.type = type
    }

    public var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(type.tintColor)
                    .frame(width: 24, height: 24)

                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.primaryText)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.cardBackground)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(type.tintColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}
