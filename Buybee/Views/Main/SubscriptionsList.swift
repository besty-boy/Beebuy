import SwiftUI
import SwiftData

struct SubscriptionsList: View {
    let subscriptions: [Subscription]
    var onAdd: () -> Void = {}
    var isSearching = false
    var referenceDate = Date()
    @Environment(\.modelContext) private var modelContext
    @State private var editing: Subscription?
    @State private var pendingDeletion: [Subscription] = []
    @State private var showDeleteConfirmation = false
    @State private var deletionError = false

    private var sortedSubscriptions: [Subscription] {
        // Compute each next date once, not inside every sorting comparison.
        let dated: [(subscription: Subscription, date: Date)] = subscriptions.map {
            (subscription: $0, date: $0.schedule.nextPayment(onOrAfter: referenceDate) ?? Date.distantFuture)
        }
        let sorted = dated.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            let comparison = lhs.subscription.name.localizedStandardCompare(rhs.subscription.name)
            if comparison != .orderedSame { return comparison == .orderedAscending }
            return lhs.subscription.id.uuidString < rhs.subscription.id.uuidString
        }
        return sorted.map { $0.subscription }
    }

    var body: some View {
        Group {
            if subscriptions.isEmpty {
                ContentUnavailableView {
                    Label(isSearching ? "Aucun résultat" : "Aucun abonnement", systemImage: "creditcard")
                } description: {
                    Text(isSearching ? "Essayez un autre nom." : "Ajoutez votre premier abonnement pour commencer le suivi.")
                } actions: {
                    if !isSearching { Button("Ajouter un abonnement", action: onAdd).buttonStyle(.borderedProminent) }
                }
            } else {
                ForEach(sortedSubscriptions) { subscription in
                    Button { editing = subscription } label: {
                        SubscriptionRow(subscription: subscription, referenceDate: referenceDate)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Modifier cet abonnement")
                }
                .onDelete { offsets in
                    let snapshot = sortedSubscriptions
                    pendingDeletion = offsets.map { snapshot[$0] }
                    showDeleteConfirmation = true
                }
            }
        }
        .sheet(item: $editing) { AddSubscriptionView(subscription: $0) }
        .confirmationDialog("Supprimer ces abonnements ?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Supprimer", role: .destructive, action: delete)
            Button("Annuler", role: .cancel) { pendingDeletion = [] }
        } message: { Text("Les données et les rappels associés seront supprimés.") }
        .alert("Suppression impossible", isPresented: $deletionError) {
            Button("OK", role: .cancel) {}
        } message: { Text("Aucun changement n’a été enregistré. Réessayez.") }
    }

    private func delete() {
        let identifiers = pendingDeletion.map(\.notificationIdentifier)
        for subscription in pendingDeletion { modelContext.delete(subscription) }
        do {
            try modelContext.save()
            Task {
                for identifier in identifiers { await NotificationManager.shared.cancel(identifier: identifier) }
                await NotificationManager.shared.refresh(context: modelContext)
            }
        } catch {
            modelContext.rollback()
            deletionError = true
        }
        pendingDeletion = []
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription
    var referenceDate = Date()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Legacy remote URLs stay in the model but are not fetched without user consent.
            ServiceIconView(iconName: subscription.iconName, imageName: subscription.imageName,
                            color: subscription.serviceColor, size: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(subscription.name).font(.headline)
                if let next = subscription.schedule.nextPayment(onOrAfter: referenceDate) {
                    Text("Prochain paiement : \(next.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Paiement passé : \(subscription.startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let end = subscription.endDate {
                    Text("Valide jusqu’au \(end.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if dynamicTypeSize.isAccessibilitySize { price }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 4)
                price
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var price: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subscription.amount, format: .currency(code: "EUR")).font(.headline)
            Text(subscription.isOneTime ? "Paiement unique" : subscription.billingCycle.displayName)
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
