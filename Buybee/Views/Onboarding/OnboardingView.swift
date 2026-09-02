import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("creditcard.fill", "Vos abonnements, au même endroit",
         "Ajoutez vos services et leurs montants. Vos données restent sur cet appareil, sans compte ni connexion bancaire."),
        ("calendar", "Comprenez vos dépenses",
         "Consultez les prélèvements prévus chaque mois et touchez une date pour en voir le détail."),
        ("bell.fill", "Des rappels à votre choix",
         "Activez les alertes depuis le bouton Rappels. Ouvrez régulièrement Buybee pour renouveler les prochaines notifications.")
    ]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button("Passer") { showOnboarding = false }.frame(minHeight: 44)
            }
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: pages[currentPage].icon)
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)
                        .padding(24)
                        .accessibilityHidden(true)
                    Text(pages[currentPage].title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text(pages[currentPage].subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            Text("Étape \(currentPage + 1) sur \(pages.count)")
                .font(.caption).foregroundStyle(.secondary)
            Button(currentPage == pages.count - 1 ? "Commencer" : "Continuer") {
                if currentPage == pages.count - 1 {
                    showOnboarding = false
                } else {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { currentPage += 1 }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(minHeight: 44)
        }
        .padding(24)
    }
}

#Preview { OnboardingView(showOnboarding: .constant(true)) }
