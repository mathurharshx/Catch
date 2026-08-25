import SwiftUI
import WidgetKit
import Combine

/// Centralized, offline-first data manager for Catch.
/// Supports atomic storage in App Group container for instant widget synchronization.
@MainActor
public final class DataStore: ObservableObject {
    public static let shared = DataStore()

    @Published public private(set) var items: [CaptureItem] = []

    private let fileManager = FileManager.default
    private let fileName = "catch_items.json"
    private let appGroupId = "group.com.catch.app"

    public init() {
        loadItems()
        // If empty on very first install, load initial sample starter capture
        if items.isEmpty {
            loadInitialDemoDataIfNeeded()
        } else if !items.contains(where: { $0.checklistItems != nil && !$0.checklistItems!.isEmpty }) {
            let checklistTask = CaptureItem(
                type: .task,
                content: "Prepare for client launch",
                createdAt: Date().addingTimeInterval(-1800),
                source: .text,
                isCompleted: false,
                checklistItems: [
                    ChecklistItem(title: "Finalize Figma brand assets", isCompleted: true),
                    ChecklistItem(title: "Review analytics dashboard", isCompleted: false),
                    ChecklistItem(title: "Send onboarding invite", isCompleted: false)
                ]
            )
            items.insert(checklistTask, at: 0)
            persistItems()
        }
    }

    // MARK: - File URL
    private var storageFileURL: URL {
        if let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) {
            return containerURL.appendingPathComponent(fileName)
        }
        // Fallback to Documents directory
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }

    // MARK: - CRUD Operations

    /// Saves a new capture instantly to memory and disk
    @discardableResult
    public func save(
        content: String,
        type: CaptureType = .note,
        source: CaptureSource = .text,
        amount: Double? = nil,
        currency: String? = nil,
        merchant: String? = nil,
        expenseCategory: String? = nil,
        reminderDate: Date? = nil,
        checklistItems: [ChecklistItem]? = nil,
        transcription: String? = nil
    ) -> CaptureItem {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        var finalAmount = amount
        var finalCurrency = currency
        var finalMerchant = merchant

        // Auto-extract expense if category is expense or amount isn't explicitly supplied
        if type == .expense && finalAmount == nil {
            if let parsed = ExpenseParser.parse(text: trimmed, defaultCurrency: UserSettings.shared.defaultCurrency) {
                finalAmount = parsed.amount
                finalCurrency = parsed.currency
                finalMerchant = parsed.merchant
            }
        }

        let item = CaptureItem(
            type: type,
            content: trimmed,
            createdAt: Date(),
            updatedAt: Date(),
            source: source,
            isCompleted: false,
            reminderDate: reminderDate,
            checklistItems: checklistItems,
            amount: finalAmount,
            currency: finalCurrency ?? UserSettings.shared.defaultCurrency,
            merchant: finalMerchant,
            expenseCategory: expenseCategory,
            audioFileName: nil,
            transcription: transcription,
            metadata: [:]
        )

        // Insert at the beginning for immediate reverse-chronological order
        items.insert(item, at: 0)
        persistItems()

        // Schedule local reminder if specified
        if let reminderDate = reminderDate, reminderDate > Date() {
            NotificationManager.shared.scheduleReminder(for: item)
        }

        // Haptic feedback & Widget timeline reload
        HapticsManager.shared.captureSaved()
        WidgetCenter.shared.reloadAllTimelines()

        return item
    }

    /// Updates an existing item
    public func update(_ item: CaptureItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        var updated = item
        updated.updatedAt = Date()
        items[index] = updated
        persistItems()

        // Update reminder
        if let reminderDate = updated.reminderDate, reminderDate > Date() {
            NotificationManager.shared.scheduleReminder(for: updated)
        } else {
            NotificationManager.shared.cancelReminder(for: updated.id)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Toggles the completion status of a task
    public func toggleTask(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        let isNowCompleted = items[index].isCompleted

        // If toggling parent task, also update all sub-items accordingly
        if let checklist = items[index].checklistItems, !checklist.isEmpty {
            items[index].checklistItems = checklist.map { item in
                var updatedItem = item
                updatedItem.isCompleted = isNowCompleted
                return updatedItem
            }
        }

        items[index].updatedAt = Date()
        persistItems()
        HapticsManager.shared.taskToggled(completed: isNowCompleted)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Toggles the completion status of an individual sub-task checklist item
    public func toggleChecklistItem(itemId: UUID, checklistItemId: UUID) {
        guard let itemIndex = items.firstIndex(where: { $0.id == itemId }) else { return }
        guard var checklist = items[itemIndex].checklistItems,
              let checkIndex = checklist.firstIndex(where: { $0.id == checklistItemId }) else { return }

        checklist[checkIndex].isCompleted.toggle()
        let isNowDone = checklist[checkIndex].isCompleted
        items[itemIndex].checklistItems = checklist

        // If all subtasks completed, auto-complete parent task; otherwise un-complete
        let allCompleted = checklist.allSatisfy { $0.isCompleted }
        items[itemIndex].isCompleted = allCompleted

        items[itemIndex].updatedAt = Date()
        persistItems()
        HapticsManager.shared.taskToggled(completed: isNowDone)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Deletes an item by ID
    public func delete(id: UUID) {
        NotificationManager.shared.cancelReminder(for: id)
        items.removeAll(where: { $0.id == id })
        persistItems()
        HapticsManager.shared.itemDeleted()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Deletes multiple items at specified offsets in a list
    public func delete(at offsets: IndexSet, in list: [CaptureItem]) {
        for index in offsets {
            let item = list[index]
            delete(id: item.id)
        }
    }

    // MARK: - Filter & Computed Metrics

    /// Returns captures matching a search query
    public func search(query: String, category: CaptureType? = nil) -> [CaptureItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return items.filter { item in
            let matchesCategory = (category == nil || item.type == category)
            if !matchesCategory { return false }

            if trimmed.isEmpty { return true }

            let contentMatches = item.content.lowercased().contains(trimmed)
            let merchantMatches = item.merchant?.lowercased().contains(trimmed) ?? false
            let categoryMatches = item.type.displayName.lowercased().contains(trimmed)
            let expenseCatMatches = item.expenseCategory?.lowercased().contains(trimmed) ?? false

            return contentMatches || merchantMatches || categoryMatches || expenseCatMatches
        }
    }

    /// Filter items by category
    public func items(for type: CaptureType) -> [CaptureItem] {
        items.filter { $0.type == type }
    }

    /// Captures created today
    public var todayItems: [CaptureItem] {
        let calendar = Calendar.current
        return items.filter { calendar.isDateInToday($0.createdAt) }
    }

    /// Active (incomplete) tasks
    public var activeTasks: [CaptureItem] {
        items.filter { $0.type == .task && !$0.isCompleted }
    }

    /// Completed tasks
    public var completedTasks: [CaptureItem] {
        items.filter { $0.type == .task && $0.isCompleted }
    }

    /// Today's total expenses sum
    public var todayExpenseTotal: Double {
        let calendar = Calendar.current
        return items
            .filter { $0.type == .expense && calendar.isDateInToday($0.createdAt) }
            .compactMap { $0.amount }
            .reduce(0, +)
    }

    /// Group items chronologically: Today, Yesterday, This Week, Earlier
    public func groupedChronologically(query: String = "", category: CaptureType? = nil) -> [(key: String, items: [CaptureItem])] {
        let filtered = search(query: query, category: category)
        let calendar = Calendar.current

        var today: [CaptureItem] = []
        var yesterday: [CaptureItem] = []
        var thisWeek: [CaptureItem] = []
        var earlier: [CaptureItem] = []

        let now = Date()

        for item in filtered {
            if calendar.isDateInToday(item.createdAt) {
                today.append(item)
            } else if calendar.isDateInYesterday(item.createdAt) {
                yesterday.append(item)
            } else if calendar.isDate(item.createdAt, equalTo: now, toGranularity: .weekOfYear) {
                thisWeek.append(item)
            } else {
                earlier.append(item)
            }
        }

        var groups: [(key: String, items: [CaptureItem])] = []
        if !today.isEmpty { groups.append(("Today", today)) }
        if !yesterday.isEmpty { groups.append(("Yesterday", yesterday)) }
        if !thisWeek.isEmpty { groups.append(("This Week", thisWeek)) }
        if !earlier.isEmpty { groups.append(("Earlier", earlier)) }

        return groups
    }

    // MARK: - Persistence & Backup

    private func loadItems() {
        let url = storageFileURL
        guard fileManager.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([CaptureItem].self, from: data)
            self.items = decoded
        } catch {
            print("Failed to load captures: \(error)")
        }
    }

    private func persistItems() {
        let url = storageFileURL
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print("Failed to persist captures: \(error)")
        }
    }

    /// Exports all captures as a formatted JSON string for data export/backup
    public func exportJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(items), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return "[]"
    }

    /// Clears all stored captures (with confirmation)
    public func clearAll() {
        for item in items {
            NotificationManager.shared.cancelReminder(for: item.id)
        }
        items.removeAll()
        persistItems()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadInitialDemoDataIfNeeded() {
        let sampleItems = [
            CaptureItem(
                type: .task,
                content: "Prepare for client launch",
                createdAt: Date().addingTimeInterval(-1800),
                source: .text,
                isCompleted: false,
                checklistItems: [
                    ChecklistItem(title: "Finalize Figma brand assets", isCompleted: true),
                    ChecklistItem(title: "Review analytics dashboard", isCompleted: false),
                    ChecklistItem(title: "Send onboarding invite", isCompleted: false)
                ]
            ),
            CaptureItem(
                type: .task,
                content: "Buy toothpaste",
                createdAt: Date().addingTimeInterval(-3600),
                source: .widget,
                isCompleted: false
            ),
            CaptureItem(
                type: .idea,
                content: "Build a website package for local gyms",
                createdAt: Date().addingTimeInterval(-7200),
                source: .voice
            ),
            CaptureItem(
                type: .expense,
                content: "₹850 Starbucks",
                createdAt: Date().addingTimeInterval(-10800),
                source: .text,
                amount: 850,
                currency: "₹",
                merchant: "Starbucks"
            ),
            CaptureItem(
                type: .note,
                content: "Client wants blue and white minimalist branding",
                createdAt: Date().addingTimeInterval(-86400),
                source: .text
            )
        ]
        self.items = sampleItems
        persistItems()
    }
}
