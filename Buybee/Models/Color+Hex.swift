import SwiftUI
import UIKit

extension Color {
    init?(hex: String) {
        let value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let digits = value.hasPrefix("#") ? String(value.dropFirst()) : value
        guard [3, 6, 8].contains(digits.count),
              digits.allSatisfy(\.isHexDigit),
              let number = UInt64(digits, radix: 16) else { return nil }
        let a, r, g, b: UInt64
        switch digits.count {
        case 3:
            (a, r, g, b) = (255, (number >> 8) * 17, (number >> 4 & 0xF) * 17, (number & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, number >> 16, number >> 8 & 0xFF, number & 0xFF)
        default:
            (a, r, g, b) = (number >> 24, number >> 16 & 0xFF, number >> 8 & 0xFF, number & 0xFF)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255,
                  blue: Double(b) / 255, opacity: Double(a) / 255)
    }

    func toHex() -> String? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        let resolved = UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "%02X%02X%02X", Int((red * 255).rounded()),
                      Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }
}
