import AppIntents
import SwiftUI

/// AppIntent allowing interactive widgets and Siri / Action Button shortcuts to trigger quick capture.
public struct QuickCaptureIntent: AppIntent {
    public static var title: LocalizedStringResource = "Quick Capture"
    public static var description = IntentDescription("Immediately opens Catch to capture a thought, task, or idea.")
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Category", default: "note")
    public var category: String

    public init() {
        self.category = "note"
    }

    public init(category: String) {
        self.category = category
    }

    @MainActor
    public func perform() async throws -> some IntentResult & OpensIntent {
        return .result()
    }
}
