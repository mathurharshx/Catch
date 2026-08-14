import Foundation

/// Proactive zero-touch intent classifier that analyzes raw input text
/// to automatically detect whether a capture is an Expense, Task, Idea, or Note.
public enum CategoryDetector {

    public struct DetectionResult: Equatable {
        public let category: CaptureType
        public let parsedExpense: ParsedExpense?
        public let confidence: Double
    }

    /// Task action keywords and prefixes (case-insensitive)
    private static let taskPrefixes: [String] = [
        "buy ", "buy:", "call ", "call:", "email ", "email:", "todo ", "todo:", "to-do ", "to-do:",
        "finish ", "send ", "schedule ", "pick up ", "clean ", "pay ", "fix ", "meet ", "order ",
        "book ", "remind me to ", "need to ", "remember to ", "check ", "prepare ", "submit ",
        "reply to ", "ask ", "contact ", "get ", "cancel "
    ]

    /// Idea indicator prefixes (case-insensitive)
    private static let ideaPrefixes: [String] = [
        "idea:", "idea -", "idea:", "new idea:", "concept:", "what if ", "startup idea:",
        "app idea:", "feature idea:", "thought:", "build a ", "build an ", "create a ",
        "project idea:", "business idea:"
    ]

    /// Analyzes the text and suggests the most likely category.
    public static func detect(from text: String, defaultCurrency: String = "₹") -> DetectionResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return DetectionResult(category: .note, parsedExpense: nil, confidence: 0.0)
        }

        let lower = trimmed.lowercased()

        // 1. Check for Expense first (highest specificity)
        if let expense = ExpenseParser.parse(text: trimmed, defaultCurrency: defaultCurrency) {
            // High confidence if it starts with currency or spent/paid
            let startsWithCurrency = trimmed.starts(with: "₹") || trimmed.starts(with: "$") ||
                                     trimmed.starts(with: "€") || trimmed.starts(with: "£") ||
                                     lower.starts(with: "rs") || lower.starts(with: "inr") ||
                                     lower.starts(with: "spent") || lower.starts(with: "paid")
            let confidence = startsWithCurrency ? 0.95 : 0.80
            return DetectionResult(category: .expense, parsedExpense: expense, confidence: confidence)
        }

        // 2. Check for Idea prefixes
        for prefix in ideaPrefixes {
            if lower.starts(with: prefix) {
                return DetectionResult(category: .idea, parsedExpense: nil, confidence: 0.90)
            }
        }

        // 3. Check for Task action prefixes
        for prefix in taskPrefixes {
            if lower.starts(with: prefix) {
                return DetectionResult(category: .task, parsedExpense: nil, confidence: 0.85)
            }
        }

        // 4. Default to Note
        return DetectionResult(category: .note, parsedExpense: nil, confidence: 0.50)
    }
}
