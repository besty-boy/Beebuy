import Foundation
import Observation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class NotificationManager {
    static let shared = NotificationManager()
    private(set) var lastError: String?
    private var isRefreshing = false
    private var refreshRequested = false
    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            lastError = "L’autorisation des rappels n’a pas pu être demandée."
            return false
        }
    }

    /// Coalesces overlapping saves/foreground events and always fetches the latest saved data.
    func refresh(context: ModelContext) async {
        refreshRequested = true
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        while refreshRequested {
            refreshRequested = false
            lastError = nil
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus) else { continue }

            do {
                let subscriptions = try context.fetch(FetchDescriptor<Subscription>())
                let now = Date()
                // Conservative global budget; earliest reminders win, regardless of insertion order.
                let sources = subscriptions.map {
                    ReminderSource(identifier: $0.notificationIdentifier, name: $0.name,
                                   amount: $0.amount, schedule: $0.schedule)
                }
                let reminders = ReminderPlanner.reminders(for: sources, after: now)

                let pending = await center.pendingNotificationRequests()
                let owned = pending.filter { $0.identifier.hasPrefix("subscription-") }
                center.removePendingNotificationRequests(withIdentifiers: owned.map(\.identifier))
                for reminder in reminders {
                    let content = UNMutableNotificationContent()
                    content.title = "Prélèvement prévu demain"
                    content.body = "\(reminder.name) — \(reminder.amount.formatted(.currency(code: "EUR")))"
                    content.sound = .default
                    let components = Calendar.current.dateComponents(
                        [.year, .month, .day, .hour, .minute], from: reminder.date
                    )
                    let request = UNNotificationRequest(
                        identifier: reminder.identifier,
                        content: content,
                        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    )
                    try await center.add(request)
                }
            } catch {
                lastError = "Certains rappels n’ont pas pu être programmés. Réessayez depuis les réglages des rappels."
            }
        }
    }

    func cancel(identifier: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        center.removePendingNotificationRequests(withIdentifiers: pending
            .filter { $0.identifier == identifier || $0.identifier.hasPrefix(identifier + "-") }
            .map(\.identifier))
        center.removeDeliveredNotifications(withIdentifiers: delivered
            .filter { $0.request.identifier == identifier || $0.request.identifier.hasPrefix(identifier + "-") }
            .map { $0.request.identifier })
    }
}
