import SwiftUI
import SwiftData
import UIKit

struct SubscriptionTrackerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var subscriptions: [Subscription]
    @State private var selectedMonth = Date()
    @State private var showingAdd = false
    @State private var showingReminders = false
    @State private var search = ""
    @State private var referenceDate = Date()

    var body: some View {
        NavigationStack {
            // A single scrolling List keeps the calendar and rows usable at large text sizes.
            List {
                Section {
                    MonthlyOverviewCard(subscriptions: subscriptions, selectedMonth: $selectedMonth, referenceDate: referenceDate)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                if let error = NotificationManager.shared.lastError {
                    Section { Label(error, systemImage: "bell.slash").font(.callout) }
                }
                Section("Tous les abonnements") {
                    SubscriptionsList(
                        subscriptions: subscriptions.filter { search.isEmpty || $0.name.localizedStandardContains(search) },
                        onAdd: { showingAdd = true },
                        isSearching: !search.isEmpty,
                        referenceDate: referenceDate
                    )
                }
            }
            .navigationTitle("Abonnements")
            .searchable(text: $search, prompt: "Rechercher un abonnement")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingReminders = true } label: {
                        Label("Rappels", systemImage: "bell")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: {
                        Label("Ajouter un abonnement", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addSubscription")
                }
            }
            .sheet(isPresented: $showingAdd) { AddSubscriptionView() }
            .sheet(isPresented: $showingReminders) { ReminderSettingsView() }
            .task { await NotificationManager.shared.refresh(context: modelContext) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    referenceDate = .now
                    Task { await NotificationManager.shared.refresh(context: modelContext) }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                // Rebuild date-based content and reminders after midnight/time-zone changes.
                referenceDate = .now
                Task { await NotificationManager.shared.refresh(context: modelContext) }
            }
        }
    }
}

#Preview {
    SubscriptionTrackerView().modelContainer(for: Subscription.self, inMemory: true)
}
