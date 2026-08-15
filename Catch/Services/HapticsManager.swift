import UIKit

/// Manages tactile haptic feedback across the application.
@MainActor
public final class HapticsManager {
    public static let shared = HapticsManager()

    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private init() {
        notificationFeedback.prepare()
        impactLight.prepare()
        impactMedium.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
    }

    /// Satisfying snap when a capture is successfully saved (money credited / item caught feel)
    public func captureSaved() {
        guard UserSettings.shared.enableHaptics else { return }
        notificationFeedback.notificationOccurred(.success)
    }

    /// Light tap when tapping category chips or toggles
    public func categorySelected() {
        guard UserSettings.shared.enableHaptics else { return }
        selectionFeedback.selectionChanged()
    }

    /// Light impact tap
    public func light() {
        guard UserSettings.shared.enableHaptics else { return }
        impactLight.impactOccurred()
    }

    /// Satisfying click when checking/unchecking a task
    public func taskToggled(completed: Bool) {
        guard UserSettings.shared.enableHaptics else { return }
        if completed {
            impactRigid.impactOccurred()
        } else {
            impactLight.impactOccurred()
        }
    }

    /// Medium feedback on microphone tap or interactive action
    public func voiceAction() {
        guard UserSettings.shared.enableHaptics else { return }
        impactMedium.impactOccurred()
    }

    /// Warning feedback on deletion
    public func itemDeleted() {
        guard UserSettings.shared.enableHaptics else { return }
        notificationFeedback.notificationOccurred(.warning)
    }
}
