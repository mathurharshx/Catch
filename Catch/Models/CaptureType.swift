import SwiftUI

/// Represents the four core MVP capture categories, designed to be extensible in future versions.
public enum CaptureType: String, Codable, CaseIterable, Identifiable, Sendable {
    case note
    case idea
    case task
    case expense

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .note: return "Note"
        case .idea: return "Idea"
        case .task: return "Task"
        case .expense: return "Expense"
        }
    }

    public var iconName: String {
        switch self {
        case .note: return "doc.text"
        case .idea: return "lightbulb"
        case .task: return "checkmark.circle"
        case .expense: return "indianrupeesign.circle" // Dynamic or general currency icon
        }
    }

    public var filledIconName: String {
        switch self {
        case .note: return "doc.text.fill"
        case .idea: return "lightbulb.fill"
        case .task: return "checkmark.circle.fill"
        case .expense: return "creditcard.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .note: return Color(red: 0.38, green: 0.45, blue: 0.98) // Indigo / Blue
        case .idea: return Color(red: 0.96, green: 0.65, blue: 0.14) // Amber / Warm Gold
        case .task: return Color(red: 0.20, green: 0.78, blue: 0.55) // Emerald / Mint Green
        case .expense: return Color(red: 0.95, green: 0.33, blue: 0.42) // Coral / Rose
        }
    }

    public var placeholderText: String {
        switch self {
        case .note: return "What do you want to remember?"
        case .idea: return "Describe your idea..."
        case .task: return "What needs to get done?"
        case .expense: return "e.g. ₹850 Starbucks or $15 Coffee"
        }
    }
}
