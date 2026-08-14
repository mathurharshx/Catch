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
}
