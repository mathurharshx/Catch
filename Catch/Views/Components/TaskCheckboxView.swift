import SwiftUI

/// Custom animated checkbox with tactile spring micro-interactions.
public struct TaskCheckboxView: View {
    public let isCompleted: Bool
    public let onToggle: () -> Void

    @State private var isAnimating: Bool = false

    public init(isCompleted: Bool, onToggle: @escaping () -> Void) {
        self.isCompleted = isCompleted
        self.onToggle = onToggle
    }

    public var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
                isAnimating = true
            }
            onToggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAnimating = false
            }
        }) {
            ZStack {
                // Background Circle Fill
                Circle()
                    .fill(isCompleted ? Theme.accentSuccess : Color.clear)
                    .frame(width: 22, height: 22)

                // Outer Ring
                Circle()
                    .strokeBorder(isCompleted ? Theme.accentSuccess : Theme.tertiaryText.opacity(0.6), lineWidth: 1.8)
                    .frame(width: 22, height: 22)

                // Checkmark
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isAnimating ? 1.25 : 1.0)
            .contentShape(Rectangle().size(width: 36, height: 36))
        }
        .buttonStyle(.plain)
    }
}
