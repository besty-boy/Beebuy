import SwiftUI
import UIKit

struct ServiceIconView: View {
    var iconName: String?
    var imageName: String?
    var color: Color = .blue
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let imageName, UIImage(named: imageName) != nil {
                Image(imageName).resizable().scaledToFit()
            } else {
                Image(systemName: iconName ?? imageName.flatMap { Self.legacySymbols[$0] } ?? "creditcard.fill")
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(color.opacity(0.12))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }

    // Existing records retain their asset names, with system-symbol fallbacks.
    private static let legacySymbols: [String: String] = [
        "icon-netflix": "play.tv.fill",
        "icons-disney": "play.tv.fill",
        "icons-youtube": "play.rectangle.fill",
        "icons-spotify": "music.note",
        "icons-canal+": "tv.fill",
        "icons-appletv": "tv.fill",
        "icons-amazon": "shippingbox.fill",
        "icons-music": "music.note",
        "icons-adobe": "paintpalette.fill",
        "icons-canva": "paintbrush.fill",
        "icons-microsoft": "doc.text.fill",
        "icons-google": "externaldrive.fill",
        "icons-github": "chevron.left.forwardslash.chevron.right",
        "icons-chatgpt": "bubble.left.and.bubble.right.fill",
        "icons-orange": "antenna.radiowaves.left.and.right",
        "icons-free": "antenna.radiowaves.left.and.right",
        "icons-sfr": "antenna.radiowaves.left.and.right",
        "icons-bouygues": "antenna.radiowaves.left.and.right",
        "icons-uber": "car.fill",
        "icons-sncf": "tram.fill",
        "icons-togoodtogo": "leaf.fill",
        "icons-deliveroo": "takeoutbag.and.cup.and.straw.fill",
        "icons-revolut": "creditcard.fill",
        "icons-n26": "creditcard.fill"
    ]
}
