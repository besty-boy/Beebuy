//
//  PredefinedService.swift
//  Buybee
//

import SwiftUI

// MARK: - Predefined Services

struct PredefinedService {
    let name: String
    let iconName: String? // Pour SF Symbols
    let color: Color

    init(name: String, iconName: String, color: Color) {
        self.name = name
        self.iconName = iconName
        self.color = color
    }

}

extension PredefinedService {
    /// Catalogue complet de tous les services connus.
    static let all: [PredefinedService] = [
        PredefinedService(name: "Netflix", iconName: "play.tv.fill", color: .red),
        PredefinedService(name: "Disney+", iconName: "play.tv.fill", color: .blue),
        PredefinedService(name: "YouTube Premium", iconName: "play.rectangle.fill", color: .red),
        PredefinedService(name: "Spotify", iconName: "music.note", color: .green),
        PredefinedService(name: "Amazon Prime Video", iconName: "shippingbox.fill", color: .blue),
        PredefinedService(name: "Canal+", iconName: "tv.fill", color: .primary),
        PredefinedService(name: "Apple TV+", iconName: "tv.fill", color: .gray),
        PredefinedService(name: "Apple Musique", iconName: "music.note", color: .green),
        PredefinedService(name: "Apple One", iconName: "applelogo", color: .primary),
        PredefinedService(name: "Adobe Creative Cloud", iconName: "paintpalette.fill", color: .purple),
        PredefinedService(name: "Canva Pro", iconName: "paintbrush.fill", color: .cyan),
        PredefinedService(name: "Microsoft 365", iconName: "doc.text.fill", color: .blue),
        PredefinedService(name: "iCloud", iconName: "icloud.fill", color: .blue),
        PredefinedService(name: "Google One", iconName: "externaldrive.fill", color: .red),
        PredefinedService(name: "GitHub Pro", iconName: "chevron.left.forwardslash.chevron.right", color: .primary),
        PredefinedService(name: "ChatGPT Plus", iconName: "bubble.left.and.bubble.right.fill", color: .purple),
        PredefinedService(name: "Orange", iconName: "antenna.radiowaves.left.and.right", color: .orange),
        PredefinedService(name: "Free Mobile", iconName: "antenna.radiowaves.left.and.right", color: .red),
        PredefinedService(name: "SFR", iconName: "antenna.radiowaves.left.and.right", color: .red),
        PredefinedService(name: "Bouygues", iconName: "antenna.radiowaves.left.and.right", color: .blue),
        PredefinedService(name: "Uber One", iconName: "car.fill", color: .primary),
        PredefinedService(name: "SNCF Max", iconName: "tram.fill", color: .red),
        PredefinedService(name: "Too Good To Go", iconName: "leaf.fill", color: .green),
        PredefinedService(name: "Deliveroo Plus", iconName: "takeoutbag.and.cup.and.straw.fill", color: .teal),
        PredefinedService(name: "Amazon Prime", iconName: "shippingbox.fill", color: .orange),
        PredefinedService(name: "Revolut Premium", iconName: "creditcard.fill", color: .blue),
        PredefinedService(name: "N26 Metal", iconName: "creditcard.fill", color: .gray)
    ]
}
