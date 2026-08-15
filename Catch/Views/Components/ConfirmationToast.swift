import SwiftUI

/// Satisfying instant confirmation toast with Catchy the mascot ("Catchy caught it!")
public struct ConfirmationToast: View {
    public let message: String
    public let type: CaptureType

    public init(message: String, type: CaptureType) {
        self.message = message
        self.type = type
    }

    public var body: some View {
        HStack(spacing: 10) {
            CatchyMascotView(pose: .celebrating, size: 24, animated: true)

            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Theme.primaryText)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(type.tintColor)
                .padding(5)
                .background(type.tintColor.opacity(0.15))
                .clipShape(Circle())
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
