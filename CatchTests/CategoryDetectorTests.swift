import XCTest
@testable import Catch

final class CategoryDetectorTests: XCTestCase {

    func testExpenseDetection() {
        let testCases = [
            "₹850 Starbucks",
            "$14 Lunch",
            "spent 500 on shoes",
            "paid 320 for uber",
            "120 rs auto"
        ]

        for text in testCases {
            let result = CategoryDetector.detect(from: text, defaultCurrency: "₹")
            XCTAssertEqual(result.category, .expense, "Failed for text: \(text)")
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        }
    }

    func testTaskDetection() {
        let testCases = [
            "buy toothpaste tomorrow",
            "call Rahul at 7",
            "email client about invoice",
            "finish project proposal",
            "todo: review analytics",
            "schedule dentist appointment",
            "pick up groceries"
        ]

        for text in testCases {
            let result = CategoryDetector.detect(from: text)
            XCTAssertEqual(result.category, .task, "Failed for text: \(text)")
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        }
    }

    func testIdeaDetection() {
        let testCases = [
            "idea: website package for gyms",
            "concept: lockscreen capture app",
            "what if we build a solar powered drone",
            "startup idea: personal AI memory"
        ]

        for text in testCases {
            let result = CategoryDetector.detect(from: text)
            XCTAssertEqual(result.category, .idea, "Failed for text: \(text)")
            XCTAssertGreaterThanOrEqual(result.confidence, 0.8)
        }
    }

    func testNoteFallback() {
        let genericText = "The meeting room code is 4920"
        let result = CategoryDetector.detect(from: genericText)
        XCTAssertEqual(result.category, .note)
    }
}
