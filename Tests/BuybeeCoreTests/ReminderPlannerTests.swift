import XCTest
@testable import BuybeeCore

final class ReminderPlannerTests: XCTestCase {
    func testGlobalLimitAndOrderIndependentOfInsertion() {
        let now = Date(timeIntervalSince1970: 1_788_350_400)
        let sources = (0..<100).map { index in
            ReminderSource(
                identifier: "subscription-\(index)", name: "Test", amount: 1,
                schedule: BillingSchedule(startDate: now.addingTimeInterval(Double(index + 2) * 86400),
                                          cycle: .monthly, isOneTime: false)
            )
        }
        let forward = ReminderPlanner.reminders(for: sources, after: now)
        let reverse = ReminderPlanner.reminders(for: sources.reversed(), after: now)
        XCTAssertEqual(forward.count, 60)
        XCTAssertEqual(forward.map(\.identifier), reverse.map(\.identifier))
        XCTAssertTrue(zip(forward, forward.dropFirst()).allSatisfy { $0.date <= $1.date })
        XCTAssertEqual(Set(forward.map(\.identifier)).count, 60)
    }

    func testSinglePaymentIsNeverRepeatedByPlanner() {
        let now = Date()
        let source = ReminderSource(
            identifier: "single", name: "Unique", amount: 1,
            schedule: BillingSchedule(startDate: now.addingTimeInterval(86400 * 3),
                                      cycle: .monthly, isOneTime: true)
        )
        XCTAssertEqual(ReminderPlanner.reminders(for: [source], after: now).count, 1)
        XCTAssertTrue(ReminderPlanner.reminders(for: [source], after: now, limit: 0).isEmpty)
    }
}
