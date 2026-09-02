import XCTest
@testable import Catch

@MainActor
final class DataStoreTests: XCTestCase {

    func testDataStoreSaveAndSearch() {
        let store = DataStore.shared
        let initialCount = store.items.count

        let saved = store.save(
            content: "UniqueTestTaskIdentifier",
            type: .task,
            source: .text
        )

        XCTAssertEqual(store.items.count, initialCount + 1)
        XCTAssertEqual(store.items.first?.id, saved.id)

        // Search test
        let results = store.search(query: "UniqueTestTaskIdentifier")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "UniqueTestTaskIdentifier")

        // Toggle task
        XCTAssertFalse(saved.isCompleted)
        store.toggleTask(id: saved.id)
        XCTAssertTrue(store.items.first(where: { $0.id == saved.id })?.isCompleted == true)

        // Cleanup
        store.delete(id: saved.id)
        XCTAssertEqual(store.items.count, initialCount)
    }

    func testExpenseParsingOnSave() {
        let store = DataStore.shared
        let item = store.save(
            content: "₹950 Dinner with team",
            type: .expense,
            source: .text
        )

        XCTAssertEqual(item.amount, 950)
        XCTAssertEqual(item.currency, "₹")
        XCTAssertEqual(item.merchant, "Dinner with team")

        store.delete(id: item.id)
    }

    func testBareNumberExpenseParsingOnSave() {
        let store = DataStore.shared
        let item = store.save(
            content: "750 cafe",
            type: .expense,
            source: .text
        )

        XCTAssertEqual(item.amount, 750)
        XCTAssertEqual(item.currency, "₹")
        XCTAssertEqual(item.merchant, "cafe")
        XCTAssertEqual(item.displayTitle, "₹750 Cafe")

        store.delete(id: item.id)
    }

    func testMerchantFirstExpenseParsingOnSave() {
        let store = DataStore.shared
        let item = store.save(
            content: "cafe 750",
            type: .expense,
            source: .text
        )

        XCTAssertEqual(item.amount, 750)
        XCTAssertEqual(item.currency, "₹")
        XCTAssertEqual(item.merchant, "cafe")
        XCTAssertEqual(item.displayTitle, "₹750 Cafe")

        store.delete(id: item.id)
    }

    func testChecklistSubtaskToggle() {
        let store = DataStore.shared
        let checklist = [
            ChecklistItem(title: "Step 1", isCompleted: false),
            ChecklistItem(title: "Step 2", isCompleted: false)
        ]

        let item = store.save(
            content: "Multi-step Task",
            type: .task,
            checklistItems: checklist
        )

        let step1Id = item.checklistItems![0].id
        let step2Id = item.checklistItems![1].id

        // Toggle step 1
        store.toggleChecklistItem(itemId: item.id, checklistItemId: step1Id)
        var currentItem = store.items.first(where: { $0.id == item.id })
        XCTAssertTrue(currentItem?.checklistItems?.first(where: { $0.id == step1Id })?.isCompleted == true)
        XCTAssertFalse(currentItem?.isCompleted == true)

        // Toggle step 2 -> all subtasks done -> parent task should be marked completed
        store.toggleChecklistItem(itemId: item.id, checklistItemId: step2Id)
        currentItem = store.items.first(where: { $0.id == item.id })
        XCTAssertTrue(currentItem?.isCompleted == true)

        // Clean up
        store.delete(id: item.id)
    }
}
