import SwiftUI
import SwiftData

@main
struct BuybeeApp: App {
    var body: some Scene {
        WindowGroup {
            switch AppModelContainer.result {
            case .success(let container):
                AppRootView()
                    .modelContainer(container)
            case .failure:
                ContentUnavailableView(
                    "Données indisponibles",
                    systemImage: "externaldrive.badge.exclamationmark",
                    description: Text("Impossible d’ouvrir vos données. Relancez l’app. Si le problème persiste, conservez l’app installée pour ne pas perdre vos données et contactez le mainteneur.")
                )
            }
        }
    }
}
