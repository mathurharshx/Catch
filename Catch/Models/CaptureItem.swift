import Foundation

/// Individual sub-task checklist item within a Task capture.
public struct ChecklistItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var isCompleted: Bool

    public init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

/// Core data model representing any captured item in Catch.
/// Designed according to the "Capture First, Organize Later" philosophy.
/// Preserves the verbatim original raw text while allowing structured metadata.
public struct CaptureItem: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var type: CaptureType
    public var content: String // Raw verbatim text entered or transcribed
    public var createdAt: Date
    public var updatedAt: Date
    public var source: CaptureSource
    public var isCompleted: Bool // Relevant for tasks
    public var reminderDate: Date? // Local notification trigger

    // Task-specific checklist / subtasks
    public var checklistItems: [ChecklistItem]?

    // Expense-specific structured fields
    public var amount: Double?
    public var currency: String?
    public var merchant: String?
    public var expenseCategory: String?

    // Voice-specific fields
    public var audioFileName: String?
    public var transcription: String?

    // Extensible key-value store for future V2 AI fields (confidence, entities, tags, etc.)
    public var metadata: [String: String]

    public init(
        id: UUID = UUID(),
        type: CaptureType = .note,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        source: CaptureSource = .text,
        isCompleted: Bool = false,
        reminderDate: Date? = nil,
        checklistItems: [ChecklistItem]? = nil,
        amount: Double? = nil,
        currency: String? = nil,
        merchant: String? = nil,
        expenseCategory: String? = nil,
        audioFileName: String? = nil,
        transcription: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.source = source
        self.isCompleted = isCompleted
        self.reminderDate = reminderDate
        self.checklistItems = checklistItems
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.expenseCategory = expenseCategory
        self.audioFileName = audioFileName
        self.transcription = transcription
        self.metadata = metadata
    }

    /// Formatted display string for expense amounts
    public var formattedAmount: String? {
        guard let amount = amount else { return nil }
        let symbol = currency ?? "₹"
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = (amount.truncatingRemainder(dividingBy: 1) == 0) ? 0 : 2
        let numberString = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "\(symbol)\(numberString)"
    }

    /// Count of completed checklist items
    public var completedChecklistCount: Int {
        checklistItems?.filter { $0.isCompleted }.count ?? 0
    }

    /// Total count of checklist items
    public var totalChecklistCount: Int {
        checklistItems?.count ?? 0
    }

    /// Relative or readable time formatted
    public var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    /// Date header grouping (Today, Yesterday, or formatted date)
    public var dateGroupingKey: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(createdAt) {
            return "Today"
        } else if calendar.isDateInYesterday(createdAt) {
            return "Yesterday"
        } else if calendar.isDate(createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // e.g. "Wednesday"
            return formatter.string(from: createdAt)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: createdAt)
        }
    }
}

/// Configuration model for presenting the Quick Capture sheet reliably with specific category/source.
public struct CaptureSheetConfig: Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var category: CaptureType?
    public var source: CaptureSource

    public init(id: UUID = UUID(), category: CaptureType? = nil, source: CaptureSource = .text) {
        self.id = id
        self.category = category
        self.source = source
    }
}
