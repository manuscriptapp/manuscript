import SwiftUI

extension Color {
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
} 
