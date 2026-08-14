import XCTest
@testable import Catch

final class ExpenseParserTests: XCTestCase {

    func testCurrencySymbolFirst() {
        let input = "₹850 Starbucks"
        let parsed = ExpenseParser.parse(text: input, defaultCurrency: "₹")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.amount, 850)
        XCTAssertEqual(parsed?.currency, "₹")
        XCTAssertEqual(parsed?.merchant, "Starbucks")
    }

    func testDollarDecimal() {
        let input = "$14.50 Lunch at Chipotle"
        let parsed = ExpenseParser.parse(text: input, defaultCurrency: "$")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.amount, 14.50)
        XCTAssertEqual(parsed?.currency, "$")
        XCTAssertEqual(parsed?.merchant, "Lunch at Chipotle")
    }

    func testNumberThenCurrency() {
        let input = "320 rs Uber ride"
        let parsed = ExpenseParser.parse(text: input, defaultCurrency: "₹")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.amount, 320)
        XCTAssertEqual(parsed?.currency, "₹")
        XCTAssertEqual(parsed?.merchant, "Uber ride")
    }

    func testSpentPrefix() {
        let input = "spent 450 on groceries"
        let parsed = ExpenseParser.parse(text: input, defaultCurrency: "₹")
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.amount, 450)
        XCTAssertEqual(parsed?.merchant, "groceries")
    }

    func testNonExpenseString() {
        let input = "Remember to call mom tomorrow"
        let parsed = ExpenseParser.parse(text: input)
        XCTAssertNil(parsed)
    }
}
