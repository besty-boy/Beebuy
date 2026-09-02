//
//  PredefinedServicePicker.swift
//  Buybee
//

import SwiftUI

// MARK: - Predefined Service Picker

/// Grille de services populaires, réutilisable (écran d'ajout, futures vues).
struct PredefinedServicePicker: View {
    let services: [PredefinedService]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onSelect: (PredefinedService) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 220 : 120))], spacing: 12) {
            ForEach(services, id: \.name) { service in
                Button {
                    onSelect(service)
                } label: {
                    VStack(spacing: 8) {
                        ServiceIconView(
                            iconName: service.iconName,
                            color: service.color,
                            size: 40
                        )

                        Text(service.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)

                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}
