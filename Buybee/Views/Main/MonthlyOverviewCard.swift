import SwiftUI

struct MonthlyOverviewCard: View {
    let subscriptions: [Subscription]
    @Binding var selectedMonth: Date
    var referenceDate = Date()

    var body: some View {
        if let interval = Calendar.current.dateInterval(of: .month, for: selectedMonth) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prélèvements du mois").font(.subheadline).foregroundStyle(.secondary)
                    Text(subscriptions.reduce(Decimal.zero) { $0 + $1.total(in: interval) },
                         format: .currency(code: "EUR"))
                        .font(.largeTitle.weight(.semibold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("Selon les échéances enregistrées, sans connexion bancaire.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                MonthlyCalendarView(subscriptions: subscriptions, selectedMonth: $selectedMonth, referenceDate: referenceDate)
            }
            .padding(.vertical, 8)
        }
    }
}
