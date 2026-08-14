import XCTest
@testable import Catch

final class CaptureItemTests: XCTestCase {

    func testCaptureItemEncodingDecoding() throws {
        let original = CaptureItem(
            type: .expense,
            content: "₹850 Starbucks",
            createdAt: Date(),
            source: .widget,
            amount: 850,
            currency: "₹",
            merchant: "Starbucks",
            metadata: ["testKey": "testVal"]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CaptureItem.self, from: data)

        XCTAssertEqual(original.id, decoded.id)
        XCTAssertEqual(original.content, decoded.content)
        XCTAssertEqual(original.type, decoded.type)
        XCTAssertEqual(original.amount, decoded.amount)
        XCTAssertEqual(original.merchant, decoded.merchant)
        XCTAssertEqual(original.metadata["testKey"], "testVal")
    }

    func testFormattedAmount() {
        var item = CaptureItem(content: "Coffee", amount: 15.00, currency: "$")
        XCTAssertEqual(item.formattedAmount, "$15")

        item.amount = 15.50
        XCTAssertEqual(item.formattedAmount, "$15.50")
    }
}
