import SwiftUI
import SwiftData

/// Editing uses local draft values: Cancel never mutates the persisted model.
struct AddSubscriptionView: View {
    var subscription: Subscription?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var amountText = ""
    @State private var billingCycle: BillingCycle = .monthly
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var isOneTime = false
    @State private var endDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedService: PredefinedService?
    @State private var showingServices = true
    @State private var search = ""
    @State private var didLoad = false
    @State private var isSaving = false
    @State private var saveError: String?
    @FocusState private var amountFocused: Bool

    private var amount: Decimal? { SubscriptionValidation.parseAmount(amountText) }
    private var canSave: Bool {
        guard let amount else { return false }
        return SubscriptionValidation.isValid(
            name: name, amount: amount, start: startDate, end: isOneTime ? endDate : nil
        )
    }
    private var services: [PredefinedService] {
        PredefinedService.all.filter { search.isEmpty || $0.name.localizedStandardContains(search) }
    }

    var body: some View {
        NavigationStack {
            Form {
                if showingServices {
                    Section {
                        Button("Créer un abonnement personnalisé") { showingServices = false }
                        TextField("Rechercher un service", text: $search)
                        PredefinedServicePicker(services: services) { service in
                            selectedService = service
                            name = service.name
                            // Prices are entered by the user; no stale catalogue prices.
                            showingServices = false
                            amountFocused = true
                        }
                        if services.isEmpty { Text("Aucun service trouvé.").foregroundStyle(.secondary) }
                    } header: {
                        Text("Choisir un service")
                    } footer: {
                        Text("Saisissez le prix de votre offre. Buybee ne récupère pas les tarifs auprès des services.")
                    }
                } else {
                    Section("Informations") {
                        if subscription == nil {
                            Button("Choisir un autre service") { showingServices = true }
                        }
                        TextField("Nom du service", text: $name)
                            .textInputAutocapitalization(.words)
                            .accessibilityIdentifier("subscriptionName")
                        HStack {
                            Text("Montant (€)")
                            TextField("0,00", text: $amountText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .focused($amountFocused)
                                .accessibilityLabel("Montant en euros")
                                .accessibilityIdentifier("subscriptionAmount")
                        }
                        if !amountText.isEmpty && amount == nil {
                            Text("Entrez un montant positif, avec au maximum deux décimales.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Toggle("Paiement unique", isOn: $isOneTime)
                        if !isOneTime {
                            Picker("Fréquence", selection: $billingCycle) {
                                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                                    Text(cycle.displayName).tag(cycle)
                                }
                            }
                        }
                        DatePicker(
                            isOneTime ? "Date du paiement" : "Premier prélèvement",
                            selection: $startDate, displayedComponents: .date
                        )
                        if isOneTime {
                            DatePicker("Fin de validité", selection: $endDate, in: startDate..., displayedComponents: .date)
                        }
                    } header: {
                        Text("Facturation")
                    } footer: {
                        Text(isOneTime
                             ? "Un seul paiement à la date indiquée. La fin de validité ne crée aucun nouveau prélèvement."
                             : "Les prélèvements en fin de mois sont ramenés au dernier jour disponible, sans décaler les mois suivants.")
                    }
                    .onChange(of: startDate) { _, newDate in
                        if endDate < newDate { endDate = newDate }
                    }
                    .onChange(of: isOneTime) { _, enabled in
                        if enabled && endDate < startDate { endDate = startDate }
                    }
                }
            }
            .navigationTitle(subscription == nil ? "Ajouter" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !showingServices {
                        Button("Enregistrer", action: save)
                            .disabled(!canSave || isSaving)
                            .accessibilityIdentifier("saveSubscription")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Terminé") { amountFocused = false }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .onAppear(perform: loadDraft)
            .alert("Enregistrement impossible", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(saveError ?? "") }
        }
    }

    private func loadDraft() {
        guard !didLoad else { return }
        didLoad = true
        guard let subscription else { return }
        name = subscription.name
        amountText = NSDecimalNumber(decimal: subscription.amount).stringValue
            .replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
        billingCycle = subscription.billingCycle
        startDate = Calendar.current.startOfDay(for: subscription.startDate)
        isOneTime = subscription.isOneTime
        endDate = max(startDate, subscription.endDate ?? startDate)
        showingServices = false
    }

    private func save() {
        guard canSave, let amount, !isSaving else { return }
        isSaving = true
        let record = subscription ?? Subscription(
            name: "", amount: amount, billingCycle: billingCycle, startDate: startDate
        )
        record.name = SubscriptionValidation.cleanName(name)
        record.amount = amount
        record.billingCycle = billingCycle
        record.startDate = Calendar.current.startOfDay(for: startDate)
        record.endDate = isOneTime ? Calendar.current.startOfDay(for: endDate) : nil
        if let selectedService {
            record.iconName = selectedService.iconName
            record.imageName = nil
            record.serviceColorHex = selectedService.color.toHex()
        }
        if subscription == nil { modelContext.insert(record) }
        do {
            try modelContext.save()
            Task { await NotificationManager.shared.refresh(context: modelContext) }
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = "Vos modifications n’ont pas été enregistrées. Vérifiez l’espace disponible et réessayez."
        }
        isSaving = false
    }
}

#Preview {
    AddSubscriptionView().modelContainer(for: Subscription.self, inMemory: true)
}
