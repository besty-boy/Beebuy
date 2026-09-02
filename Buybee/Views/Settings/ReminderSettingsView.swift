import SwiftUI
import SwiftData
import UserNotifications

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var status: UNAuthorizationStatus = .notDetermined
    @State private var isWorking = false
    @State private var pendingCount = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Une alerte à 10 h la veille du prélèvement, selon le fuseau de l’appareil lors de la programmation.")
                    Text("Les 60 prochains rappels sont préparés et renouvelés à l’ouverture de l’app. Ouvrez Buybee régulièrement pour prolonger cette couverture.")
                    Text("Le nom et le montant peuvent apparaître sur l’écran verrouillé. Vous pouvez masquer les aperçus dans les réglages iOS.")
                } header: { Text("Comment fonctionnent les rappels ?") }

                Section("Autorisation") {
                    if status == .notDetermined {
                        Button("Activer les rappels") {
                            Task {
                                isWorking = true
                                _ = await NotificationManager.shared.requestPermission()
                                await refresh()
                                isWorking = false
                            }
                        }
                    } else if status == .denied {
                        Text("Les notifications sont désactivées dans les réglages iOS.")
                    } else {
                        Text("\(pendingCount) rappel(s) en attente")
                        Button("Actualiser les rappels") {
                            Task {
                                isWorking = true
                                await refresh()
                                isWorking = false
                            }
                        }
                    }
                    Button("Ouvrir les réglages iOS") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    if let error = NotificationManager.shared.lastError {
                        Text(error).foregroundStyle(.red)
                    }
                }
                .disabled(isWorking)
            }
            .navigationTitle("Rappels")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fermer") { dismiss() } } }
            .task { await refresh() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { Task { await refresh() } }
            }
        }
    }

    private func refresh() async {
        status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        await NotificationManager.shared.refresh(context: modelContext)
        pendingCount = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix("subscription-") }.count
    }
}
