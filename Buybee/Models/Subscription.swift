import Foundation
import SwiftData
import SwiftUI

@Model
final class Subscription {
    // Persisted properties are preserved to keep existing SwiftData stores compatible.
    var id = UUID()
    var name: String
    var amount: Decimal
    var billingCycle: BillingCycle
    var startDate: Date
    /// Legacy representation: a non-nil endDate denotes one payment on startDate.
    var endDate: Date?
    var iconURL: URL?
    var iconName: String?
    var imageName: String?
    var serviceColorHex: String?

    var isOneTime: Bool { endDate != nil }
    var schedule: BillingSchedule {
        BillingSchedule(startDate: startDate, cycle: billingCycle, isOneTime: isOneTime)
    }

    var serviceColor: Color {
        if let hex = serviceColorHex, let color = Color(hex: hex) {
            return ["000000", "FFFFFF"].contains(hex.uppercased()) ? .primary : color
        }
        let colors: [Color] = [.blue, .indigo, .purple, .pink, .teal, .orange]
        // Stable across launches; no randomized hash or abs(Int.min) overflow.
        let index = name.utf8.reduce(0) { ($0 * 31 + Int($1)) % colors.count }
        return colors[index]
    }

    var notificationIdentifier: String { "subscription-\(id.uuidString)" }
    var nextBillingDate: Date? { schedule.nextPayment(onOrAfter: .now) }

    /// Normalized estimate, not actual charges in a specific calendar month.
    var monthlyAmount: Decimal {
        guard !isOneTime else { return 0 }
        switch billingCycle {
        case .monthly: return amount
        case .yearly: return amount / 12
        case .weekly: return amount * 52 / 12
        }
    }

    func total(in interval: DateInterval) -> Decimal {
        amount * Decimal(schedule.payments(in: interval).count)
    }

    init(name: String, amount: Decimal, billingCycle: BillingCycle, startDate: Date,
         endDate: Date? = nil, iconName: String? = nil, imageName: String? = nil,
         serviceColor: Color? = nil) {
        self.name = name
        self.amount = amount
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.endDate = endDate
        self.iconName = iconName
        self.imageName = imageName
        self.serviceColorHex = serviceColor?.toHex()
    }
}
