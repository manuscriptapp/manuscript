//
//  CompositionModeBackground.swift
//  Manuscript
//
//  A reusable background view with vignette effect for Composition Mode.
//

import SwiftUI

// MARK: - Composition Mode Theme

enum CompositionTheme: String, CaseIterable, Identifiable {
    // Dark themes
    case teal = "Teal"
    case midnight = "Midnight"
    case sepia = "Sepia"
    case forest = "Forest"
    case slate = "Slate"
    case aurora = "Aurora"

    // Light themes
    case cream = "Cream"
    case rose = "Rose"
    case sky = "Sky"
    case mint = "Mint"
    case lavender = "Lavender"
    case paper = "Paper"

    var id: String { rawValue }

    var isLight: Bool {
        switch self {
        case .teal, .midnight, .sepia, .forest, .slate, .aurora:
            return false
        case .cream, .rose, .sky, .mint, .lavender, .paper:
            return true
        }
    }

    static var darkThemes: [CompositionTheme] {
        [.teal, .midnight, .sepia, .forest, .slate, .aurora]
    }

    static var lightThemes: [CompositionTheme] {
        [.cream, .rose, .sky, .mint, .lavender, .paper]
    }

    var outerColor: Color {
        switch self {
        // Dark themes
        case .teal:
            return Color(red: 0.05, green: 0.09, blue: 0.12)
        case .midnight:
            return Color(red: 0.05, green: 0.05, blue: 0.12)
        case .sepia:
            return Color(red: 0.12, green: 0.09, blue: 0.06)
        case .forest:
            return Color(red: 0.04, green: 0.10, blue: 0.06)
        case .slate:
            return Color(red: 0.08, green: 0.08, blue: 0.09)
        case .aurora:
            return Color(red: 0.06, green: 0.08, blue: 0.12)
        // Light themes
        case .cream:
            return Color(red: 0.96, green: 0.94, blue: 0.90)
        case .rose:
            return Color(red: 0.98, green: 0.92, blue: 0.93)
        case .sky:
            return Color(red: 0.91, green: 0.95, blue: 0.98)
        case .mint:
            return Color(red: 0.92, green: 0.97, blue: 0.94)
        case .lavender:
            return Color(red: 0.95, green: 0.93, blue: 0.98)
        case .paper:
            return Color(red: 0.97, green: 0.97, blue: 0.96)
        }
    }

    var innerColor: Color {
        switch self {
        // Dark themes
        case .teal:
            return Color(red: 0.08, green: 0.12, blue: 0.15)
        case .midnight:
            return Color(red: 0.08, green: 0.08, blue: 0.18)
        case .sepia:
            return Color(red: 0.18, green: 0.14, blue: 0.10)
        case .forest:
            return Color(red: 0.06, green: 0.14, blue: 0.08)
        case .slate:
            return Color(red: 0.12, green: 0.12, blue: 0.13)
        case .aurora:
            return Color(red: 0.10, green: 0.12, blue: 0.18)
        // Light themes (slightly darker center for subtle vignette)
        case .cream:
            return Color(red: 0.99, green: 0.97, blue: 0.94)
        case .rose:
            return Color(red: 1.0, green: 0.96, blue: 0.97)
        case .sky:
            return Color(red: 0.96, green: 0.98, blue: 1.0)
        case .mint:
            return Color(red: 0.96, green: 0.99, blue: 0.97)
        case .lavender:
            return Color(red: 0.98, green: 0.96, blue: 1.0)
        case .paper:
            return Color(red: 1.0, green: 1.0, blue: 0.99)
        }
    }

    var textColor: Color {
        isLight ? Color(white: 0.15) : Color(white: 0.85)
    }

    var iconName: String {
        switch self {
        // Dark themes
        case .teal: return "drop.fill"
        case .midnight: return "moon.stars.fill"
        case .sepia: return "book.fill"
        case .forest: return "leaf.fill"
        case .slate: return "circle.lefthalf.filled"
        case .aurora: return "sparkles"
        // Light themes
        case .cream: return "sun.max.fill"
        case .rose: return "heart.fill"
        case .sky: return "cloud.fill"
        case .mint: return "leaf.fill"
        case .lavender: return "flower.fill"
        case .paper: return "doc.fill"
        }
    }
}

// MARK: - Composition Mode Background

struct CompositionModeBackground: View {
    var theme: CompositionTheme = .teal

    // Vignette color depends on theme
    private var vignetteColor: Color {
        theme.isLight ? Color.black.opacity(0.08) : Color.black.opacity(0.4)
    }

    private var topBottomVignetteColor: Color {
        theme.isLight ? Color.black.opacity(0.04) : Color.black.opacity(0.2)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base color
                theme.outerColor

                // Radial gradient for center
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.innerColor,
                        theme.outerColor
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.7
                )

                // Horizontal vignette (darker edges)
                HStack(spacing: 0) {
                    // Left vignette
                    LinearGradient(
                        gradient: Gradient(colors: [
                            vignetteColor,
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.25)

                    Spacer()

                    // Right vignette
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            vignetteColor
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.25)
                }

                // Top vignette
                VStack(spacing: 0) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            topBottomVignetteColor,
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.15)

                    Spacer()

                    // Bottom vignette
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            topBottomVignetteColor
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: geometry.size.height * 0.15)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#if DEBUG
#Preview {
    CompositionModeBackground()
}
#endif
