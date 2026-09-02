import Foundation

enum SubscriptionValidation {
    static func cleanName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A complete decimal amount, with either French or dot decimal separator.
    static func parseAmount(_ text: String) -> Decimal? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard value.range(of: #"^[0-9]{1,8}(\.[0-9]{1,2})?$"#, options: .regularExpression) != nil,
              let amount = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")),
              amount > 0 else { return nil }
        return amount
    }

    static func isValid(name: String, amount: Decimal, start: Date, end: Date?) -> Bool {
        let trimmed = cleanName(name)
        guard !trimmed.isEmpty, trimmed.count <= 100,
              !amount.isNaN, amount > 0, amount < 100_000_000 else { return false }
        return end.map { Calendar.current.startOfDay(for: $0) >= Calendar.current.startOfDay(for: start) } ?? true
    }
}
