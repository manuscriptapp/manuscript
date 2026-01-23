//
//  CompositionModeBackground.swift
//  Manuscript
//
//  A reusable background view with vignette effect for Composition Mode.
//

import SwiftUI

struct CompositionModeBackground: View {
    // Dark teal colors inspired by Scrivener's Composition Mode
    private let outerColor = Color(red: 0.05, green: 0.09, blue: 0.12)
    private let innerColor = Color(red: 0.08, green: 0.12, blue: 0.15)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base dark color
                outerColor

                // Radial gradient for lighter center
                RadialGradient(
                    gradient: Gradient(colors: [
                        innerColor,
                        outerColor
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
                            Color.black.opacity(0.4),
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
                            Color.black.opacity(0.4)
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
                            Color.black.opacity(0.2),
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
                            Color.black.opacity(0.2)
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
