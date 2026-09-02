import XCTest
@testable import BuybeeCore

final class SubscriptionValidationTests: XCTestCase {
    func testFrenchAndDotAmounts() {
        XCTAssertEqual(SubscriptionValidation.parseAmount(" 12,99 "), Decimal(string: "12.99"))
        XCTAssertEqual(SubscriptionValidation.parseAmount("12.99"), Decimal(string: "12.99"))
        XCTAssertEqual(SubscriptionValidation.parseAmount("1"), 1)
        XCTAssertEqual(SubscriptionValidation.parseAmount("0,01"), Decimal(string: "0.01"))
    }

    func testInvalidAmountsAreRejectedEntirely() {
        for value in ["", "0", "-1", "NaN", "inf", "12abc", "1.234", "1,2,3", "1e5", "1 000", "100000000", "1."] {
            XCTAssertNil(SubscriptionValidation.parseAmount(value), value)
        }
    }

    func testNamesAreTrimmedAndBounded() {
        let now = Date()
        XCTAssertEqual(SubscriptionValidation.cleanName(" \nNetflix \n"), "Netflix")
        XCTAssertFalse(SubscriptionValidation.isValid(name: " \n ", amount: 10, start: now, end: nil))
        XCTAssertFalse(SubscriptionValidation.isValid(name: String(repeating: "a", count: 101), amount: 10, start: now, end: nil))
        XCTAssertTrue(SubscriptionValidation.isValid(name: "Netflix", amount: 10, start: now, end: nil))
    }

    func testInvalidEndDateAndNaNAreRejected() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        XCTAssertFalse(SubscriptionValidation.isValid(name: "Test", amount: 10, start: now, end: yesterday))
        XCTAssertFalse(SubscriptionValidation.isValid(name: "Test", amount: .nan, start: now, end: nil))
        XCTAssertTrue(SubscriptionValidation.isValid(name: "Test", amount: 10, start: now, end: now))
    }
}
