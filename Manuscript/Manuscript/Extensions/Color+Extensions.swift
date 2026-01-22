import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

extension Color {
    // MARK: - System Colors

    static var systemBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var systemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemGroupedBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var systemGray5: Color {
        #if os(iOS)
        return Color(UIColor.systemGray5)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    // MARK: - Color Utilities
    func darker(by percentage: Double = 0.2) -> Color {
        #if os(iOS)
        guard let components = UIColor(self).cgColor.components else { return self }
        #else
        guard let components = NSColor(self).cgColor.components else { return self }
        #endif
        let r = components[0] * (1 - percentage)
        let g = components[1] * (1 - percentage)
        let b = components[2] * (1 - percentage)
        return Color(red: r, green: g, blue: b)
    }

    /// Initialize a Color from a hex string (e.g., "#FF0000" or "FF0000")
    init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6,
              let rgb = Int(trimmed, radix: 16) else {
            return nil
        }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Convert Color to hex string
    func toHex() -> String? {
        #if os(iOS)
        guard let components = UIColor(self).cgColor.components else { return nil }
        #else
        guard let nsColor = NSColor(self).usingColorSpace(.deviceRGB),
              let components = nsColor.cgColor.components else { return nil }
        #endif

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
} 
