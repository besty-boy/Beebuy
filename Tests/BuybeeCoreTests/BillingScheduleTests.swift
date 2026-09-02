import XCTest
@testable import BuybeeCore

final class BillingScheduleTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func schedule(_ start: Date, _ cycle: BillingCycle = .monthly, oneTime: Bool = false) -> BillingSchedule {
        BillingSchedule(startDate: start, cycle: cycle, isOneTime: oneTime, calendar: calendar)
    }

    func testMonthEndDoesNotDrift() {
        let schedule = schedule(date(2025, 1, 31, 18))
        XCTAssertEqual(schedule.occurrence(at: 1), date(2025, 2, 28))
        XCTAssertEqual(schedule.occurrence(at: 2), date(2025, 3, 31))
        XCTAssertEqual(schedule.occurrence(at: 3), date(2025, 4, 30))
    }

    func testLeapDayAnnualAnchorIsRestored() {
        let schedule = schedule(date(2024, 2, 29), .yearly)
        XCTAssertEqual(schedule.occurrence(at: 1), date(2025, 2, 28))
        XCTAssertEqual(schedule.occurrence(at: 4), date(2028, 2, 29))
        XCTAssertEqual(schedule.nextPayment(onOrAfter: date(2025, 2, 28, 22)), date(2025, 2, 28))
    }

    func testTodayIsIncludedRegardlessOfTime() {
        let schedule = schedule(date(2026, 9, 2, 17))
        XCTAssertEqual(schedule.nextPayment(onOrAfter: date(2026, 9, 2, 23)), date(2026, 9, 2))
        XCTAssertEqual(schedule.nextPayment(onOrAfter: date(2026, 9, 3)), date(2026, 10, 2))
    }

    func testFutureStartIsNotChargedEarly() {
        let schedule = schedule(date(2026, 12, 5))
        XCTAssertEqual(schedule.nextPayment(onOrAfter: date(2026, 9, 2)), date(2026, 12, 5))
        XCTAssertTrue(schedule.payments(in: DateInterval(start: date(2026, 9, 1), end: date(2026, 10, 1))).isEmpty)
    }

    func testOneTimeNeverRepeats() {
        let schedule = schedule(date(2026, 8, 15), oneTime: true)
        XCTAssertNil(schedule.nextPayment(onOrAfter: date(2026, 8, 16)))
        XCTAssertNil(schedule.occurrence(at: 1))
        XCTAssertTrue(schedule.reminderDates(after: date(2026, 9, 1)).isEmpty)
        XCTAssertEqual(schedule.payments(in: DateInterval(start: date(2026, 8, 1), end: date(2026, 9, 1))), [date(2026, 8, 15)])
    }

    func testHalfOpenMonthBoundary() {
        let schedule = schedule(date(2026, 1, 1))
        XCTAssertEqual(schedule.payments(in: DateInterval(start: date(2026, 9, 1), end: date(2026, 10, 1))), [date(2026, 9, 1)])
    }

    func testWeeklyMonthCanHaveFiveCharges() {
        let schedule = schedule(date(2026, 8, 1), .weekly)
        XCTAssertEqual(schedule.payments(in: DateInterval(start: date(2026, 8, 1), end: date(2026, 9, 1))).count, 5)
    }

    func testYearlyOnlyChargedInAnniversaryMonth() {
        let schedule = schedule(date(2020, 6, 3), .yearly)
        XCTAssertTrue(schedule.payments(in: DateInterval(start: date(2026, 5, 1), end: date(2026, 6, 1))).isEmpty)
        XCTAssertEqual(schedule.payments(in: DateInterval(start: date(2026, 6, 1), end: date(2026, 7, 1))), [date(2026, 6, 3)])
    }

    func testWeeklyAcrossDaylightSavingUsesCalendarDays() {
        let schedule = schedule(date(2026, 3, 22, 18), .weekly)
        XCTAssertEqual(schedule.occurrence(at: 1), date(2026, 3, 29))
        XCTAssertEqual(schedule.occurrence(at: 2), date(2026, 4, 5))
    }

    func testReminderTomorrowBeforeTenIsKept() {
        let schedule = schedule(date(2026, 9, 3), oneTime: true)
        XCTAssertEqual(schedule.reminderDates(after: date(2026, 9, 2, 9)), [date(2026, 9, 2, 10)])
        XCTAssertTrue(schedule.reminderDates(after: date(2026, 9, 2, 11)).isEmpty)
    }

    func testReminderBudgetAndNoPastDates() {
        let now = date(2026, 9, 2, 11)
        let reminders = schedule(date(2000, 1, 31)).reminderDates(after: now, limit: 60)
        XCTAssertEqual(reminders.count, 60)
        XCTAssertTrue(reminders.allSatisfy { $0 > now && calendar.component(.hour, from: $0) == 10 })
        XCTAssertEqual(Set(reminders).count, reminders.count)
        XCTAssertTrue(schedule(now).reminderDates(after: now, limit: 0).isEmpty)
    }

    func testOldSubscriptionUsesCorrectAnchor() {
        let schedule = schedule(date(1900, 1, 31))
        XCTAssertEqual(schedule.nextPayment(onOrAfter: date(2026, 9, 1)), date(2026, 9, 30))
    }

    func testNextPaymentAgreesWithMonthScheduleAcrossYears() {
        for cycle in BillingCycle.allCases {
            for startDay in [1, 28, 29, 30, 31] {
                let schedule = schedule(date(2024, 1, startDay), cycle)
                for month in 1...36 {
                    let start = calendar.date(byAdding: .month, value: month, to: date(2024, 1, 1))!
                    let end = calendar.date(byAdding: .month, value: 1, to: start)!
                    let payments = schedule.payments(in: DateInterval(start: start, end: end))
                    for payment in payments {
                        XCTAssertEqual(schedule.nextPayment(onOrAfter: payment), payment)
                        XCTAssertTrue(payment >= start && payment < end)
                    }
                }
            }
        }
    }
}
