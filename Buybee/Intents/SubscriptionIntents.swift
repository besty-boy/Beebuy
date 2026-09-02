//
//  SubscriptionIntents.swift
//  Buybee
//

import AppIntents
import Foundation
import SwiftData

// MARK: - App Shortcuts (Siri / Raccourcis)

/// Déclare les raccourcis Siri proposés par Buybee.
/// L'utilisateur peut les ajouter dans Réglages > Siri ou dans l'app Raccourcis.
struct BuybeeShortcuts: AppShortcutsProvider {
    nonisolated static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddSubscriptionIntent(),
            phrases: [
                "Ajoute un abonnement dans \(.applicationName)",
                "Crée un abonnement dans \(.applicationName)",
            ],
            shortTitle: "Ajouter un abonnement",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: MonthlyTotalIntent(),
            phrases: [
                "Quel est le total de mes abonnements dans \(.applicationName)",
                "Combien je dépense par mois dans \(.applicationName)",
                "Total mensuel dans \(.applicationName)",
            ],
            shortTitle: "Total mensuel",
            systemImageName: "eurosign.circle.fill"
        )
        AppShortcut(
            intent: NextBillingIntent(),
            phrases: [
                "Quand est le prochain prélèvement dans \(.applicationName)",
                "Prochain prélèvement dans \(.applicationName)",
            ],
            shortTitle: "Prochain prélèvement",
            systemImageName: "calendar.badge.clock"
        )
    }
}

// MARK: - Fréquence de facturation (paramètre Siri)

enum BillingCycleAppEnum: String, AppEnum, CaseIterable {
    case weekly
    case monthly
    case yearly

    nonisolated static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Fréquence de facturation"
    }

    nonisolated static var caseDisplayRepresentations: [BillingCycleAppEnum: DisplayRepresentation] {
        [
            .weekly: "Hebdomadaire",
            .monthly: "Mensuel",
            .yearly: "Annuel",
        ]
    }

    var billingCycle: BillingCycle {
        switch self {
        case .weekly: .weekly
        case .monthly: .monthly
        case .yearly: .yearly
        }
    }
}

// MARK: - Ajouter un abonnement

struct AddSubscriptionIntent: AppIntent {
    nonisolated static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
    nonisolated static var title: LocalizedStringResource {
        "Ajouter un abonnement"
    }

    nonisolated static var description: IntentDescription {
        IntentDescription("Ajoute un abonnement au suivi Buybee.")
    }

    @Parameter(title: "Nom", requestValueDialog: "Quel est le nom de l'abonnement ?")
    var name: String

    @Parameter(title: "Montant", requestValueDialog: "Quel est le montant ?")
    var amount: Double

    @Parameter(title: "Fréquence", default: .monthly)
    var billingCycle: BillingCycleAppEnum

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount.isFinite, amount > 0,
              let decimal = SubscriptionValidation.parseAmount(String(amount)),
              SubscriptionValidation.isValid(name: name, amount: decimal, start: .now, end: nil) else {
            throw SubscriptionIntentError.invalidInput
        }
        let subscription = Subscription(
            name: SubscriptionValidation.cleanName(name),
            amount: decimal,
            billingCycle: billingCycle.billingCycle,
            startDate: .now
        )

        let context = try AppModelContainer.container().mainContext
        context.insert(subscription)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        await NotificationManager.shared.refresh(context: context)

        return .result(dialog: "\(name) a été ajouté à vos abonnements.")
    }
}

// MARK: - Total mensuel

struct MonthlyTotalIntent: AppIntent {
    nonisolated static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
    nonisolated static var title: LocalizedStringResource {
        "Total mensuel des abonnements"
    }

    nonisolated static var description: IntentDescription {
        IntentDescription("Calcule le coût mensuel de tous vos abonnements.")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let subscriptions = try AppModelContainer.container().mainContext.fetch(FetchDescriptor<Subscription>())
        let today = Calendar.current.startOfDay(for: Date())
        let total = subscriptions.filter { Calendar.current.startOfDay(for: $0.startDate) <= today }
            .reduce(Decimal.zero) { $0 + $1.monthlyAmount }
        let formatted = total.formatted(.currency(code: "EUR"))

        return .result(dialog: "Le coût mensuel moyen de vos abonnements commencés est de \(formatted), hors paiements uniques.")
    }
}

// MARK: - Prochain prélèvement

struct NextBillingIntent: AppIntent {
    nonisolated static var authenticationPolicy: IntentAuthenticationPolicy { .requiresAuthentication }
    nonisolated static var title: LocalizedStringResource {
        "Prochain prélèvement"
    }

    nonisolated static var description: IntentDescription {
        IntentDescription("Indique le prochain prélèvement à venir.")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let subscriptions = try AppModelContainer.container().mainContext.fetch(FetchDescriptor<Subscription>())

        let upcoming = subscriptions.compactMap { subscription -> (Subscription, Date)? in
            guard let date = subscription.nextBillingDate else { return nil }
            return (subscription, date)
        }
        guard let (next, nextDate) = upcoming.min(by: { $0.1 < $1.1 }) else {
            return .result(dialog: "Vous n’avez aucun prélèvement à venir.")
        }

        let date = nextDate.formatted(date: .long, time: .omitted)
        let amount = next.amount.formatted(.currency(code: "EUR"))

        return .result(dialog: "Le prochain prélèvement est \(next.name) le \(date), pour \(amount).")
    }
}

private enum SubscriptionIntentError: LocalizedError {
    case invalidInput

    var errorDescription: String? {
        "Indiquez un nom de 1 à 100 caractères et un montant positif avec au maximum deux décimales."
    }
}
