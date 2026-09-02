import Foundation

enum BillingCycle: String, CaseIterable, Codable {
    case weekly, monthly, yearly

    var displayName: String {
        switch self {
        case .weekly: "Hebdomadaire"
        case .monthly: "Mensuel"
        case .yearly: "Annuel"
        }
    }
}

/// Calendar-day billing anchored to the original date: 31 Jan → 28 Feb → 31 Mar.
/// Intervals are half-open [start, end). Time of day never changes the billing day.
struct BillingSchedule {
    let startDate: Date
    let cycle: BillingCycle
    let isOneTime: Bool
    var calendar: Calendar = .current

    private var anchor: Date { calendar.startOfDay(for: startDate) }

    func occurrence(at index: Int) -> Date? {
        guard index >= 0, !isOneTime || index == 0 else { return nil }
        switch cycle {
        case .weekly:
            return calendar.date(byAdding: .day, value: index * 7, to: anchor)
        case .monthly:
            return calendar.date(byAdding: .month, value: index, to: anchor)
        case .yearly:
            return calendar.date(byAdding: .year, value: index, to: anchor)
        }
    }

    private func estimatedIndex(for date: Date) -> Int {
        switch cycle {
        case .weekly:
            return max(0, (calendar.dateComponents([.day], from: anchor, to: date).day ?? 0) / 7)
        case .monthly:
            let first = calendar.dateInterval(of: .month, for: anchor)?.start ?? anchor
            let last = calendar.dateInterval(of: .month, for: date)?.start ?? date
            return max(0, calendar.dateComponents([.month], from: first, to: last).month ?? 0)
        case .yearly:
            return max(0, calendar.dateComponents([.year], from: anchor, to: date).year ?? 0)
        }
    }

    func nextPayment(onOrAfter date: Date) -> Date? {
        let day = calendar.startOfDay(for: date)
        if isOneTime { return anchor >= day ? anchor : nil }
        let index = estimatedIndex(for: day)
        // The estimate is at most one period behind; bounded even for very old records.
        for candidate in index...(index + 2) {
            if let payment = occurrence(at: candidate), payment >= day { return payment }
        }
        return nil
    }

    func payments(in interval: DateInterval) -> [Date] {
        guard interval.end > interval.start else { return [] }
        var index = isOneTime ? 0 : estimatedIndex(for: interval.start)
        var result: [Date] = []
        while let payment = occurrence(at: index), payment < interval.end {
            if payment >= interval.start { result.append(payment) }
            index += 1
        }
        return result
    }

    func reminderDates(after now: Date, limit: Int = 60) -> [Date] {
        guard limit > 0 else { return [] }
        var index = isOneTime ? 0 : estimatedIndex(for: now)
        var result: [Date] = []
        // Two extra occurrences cover today's payment and a reminder already passed today.
        for _ in 0..<(limit + 2) {
            guard let payment = occurrence(at: index) else { break }
            index += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: payment),
                  let reminder = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: previousDay),
                  reminder > now else { continue }
            result.append(reminder)
            if result.count == limit { break }
        }
        return result
    }
}
