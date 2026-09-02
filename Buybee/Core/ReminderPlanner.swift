import Foundation

struct ReminderSource {
    let identifier: String
    let name: String
    let amount: Decimal
    let schedule: BillingSchedule
}

struct PlannedReminder {
    let identifier: String
    let name: String
    let amount: Decimal
    let date: Date
}

enum ReminderPlanner {
    static func reminders(for sources: [ReminderSource], after now: Date, limit: Int = 60) -> [PlannedReminder] {
        guard limit > 0 else { return [] }
        var result: [PlannedReminder] = []
        for source in sources {
            for date in source.schedule.reminderDates(after: now, limit: limit) {
                result.append(PlannedReminder(
                    identifier: source.identifier + "-" + String(Int(date.timeIntervalSince1970)),
                    name: source.name, amount: source.amount, date: date
                ))
            }
            result.sort {
                if $0.date != $1.date { return $0.date < $1.date }
                return $0.identifier < $1.identifier
            }
            // Keep memory bounded as the user's list grows.
            if result.count > limit { result.removeLast(result.count - limit) }
        }
        return result
    }
}
