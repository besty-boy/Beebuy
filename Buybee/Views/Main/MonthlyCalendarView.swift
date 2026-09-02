import SwiftUI

struct MonthlyCalendarView: View {
    let subscriptions: [Subscription]
    @Binding var selectedMonth: Date
    var referenceDate = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDay: CalendarDay?

    private var calendar: Calendar { .current }
    private var month: DateInterval? { calendar.dateInterval(of: .month, for: selectedMonth) }

    var body: some View {
        if let month {
            // One grouping per render, not a computed dictionary rebuilt for every day.
            let payments = paymentsByDay(in: month)
            let days = days(in: month)
            let offset = (calendar.component(.weekday, from: month.start) - calendar.firstWeekday + 7) % 7
            VStack(spacing: 8) {
                HStack {
                    Button { changeMonth(-1) } label: {
                        Image(systemName: "chevron.left").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityLabel("Mois précédent")
                    Spacer(minLength: 0)
                    Text(month.start, format: .dateTime.month(.wide).year())
                        .font(.headline).multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 0)
                    Button { changeMonth(1) } label: {
                        Image(systemName: "chevron.right").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityLabel("Mois suivant")
                }
                .buttonStyle(.borderless)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                    ForEach(0..<7, id: \.self) { index in
                        Text(calendar.veryShortStandaloneWeekdaySymbols[(index + calendar.firstWeekday - 1) % 7])
                            .font(.caption).foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    ForEach(0..<offset, id: \.self) { _ in
                        Color.clear.frame(height: 44).accessibilityHidden(true)
                    }
                    ForEach(days, id: \.self) { day in
                        let records = payments[day] ?? []
                        Button { selectedDay = CalendarDay(date: day) } label: {
                            VStack(spacing: 4) {
                                Text(day, format: .dateTime.day()).font(.caption)
                                    .foregroundStyle(.primary)
                                    .fontWeight(records.isEmpty ? .regular : .bold)
                                Text(records.isEmpty ? " " : "\(records.count)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                calendar.isDate(day, inSameDayAs: referenceDate) ? Color.accentColor.opacity(0.15) : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay {
                                if calendar.isDate(day, inSameDayAs: referenceDate) {
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 1)
                                }
                            }
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
                        .accessibilityValue("\(records.count) prélèvement(s), \(records.reduce(Decimal.zero) { $0 + $1.amount }.formatted(.currency(code: "EUR")))")
                        .accessibilityHint("Afficher les paiements de ce jour")
                    }
                }
                Button("Revenir au mois actuel") { selectedMonth = .now }
                    .font(.caption).frame(minHeight: 44).buttonStyle(.borderless)
            }
            .sheet(item: $selectedDay) { day in
                NavigationStack {
                    List {
                        let records = payments[day.date] ?? []
                        if records.isEmpty {
                            Text("Aucun prélèvement prévu.").foregroundStyle(.secondary)
                        }
                        ForEach(records) { SubscriptionRow(subscription: $0) }
                    }
                    .navigationTitle(day.date.formatted(date: .abbreviated, time: .omitted))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Fermer") { selectedDay = nil }
                        }
                    }
                }
            }
        }
    }

    private func days(in month: DateInterval) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month.start) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month.start) }
    }

    private func paymentsByDay(in month: DateInterval) -> [Date: [Subscription]] {
        var result: [Date: [Subscription]] = [:]
        for subscription in subscriptions {
            for day in subscription.schedule.payments(in: month) {
                result[day, default: []].append(subscription)
            }
        }
        return result
    }

    private func changeMonth(_ offset: Int) {
        guard let month, let date = calendar.date(byAdding: .month, value: offset, to: month.start) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedMonth = date }
    }
}

private struct CalendarDay: Identifiable {
    let date: Date
    var id: Date { date }
}
