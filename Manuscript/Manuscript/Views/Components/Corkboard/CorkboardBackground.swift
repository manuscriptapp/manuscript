import SwiftUI

/// A realistic corkboard background using procedural generation
struct CorkboardBackground: View {
    /// Controls the density of cork grain details
    var grainDensity: Double = 1.0

    /// Base cork colors
    private let corkBaseColor = Color(red: 0.76, green: 0.60, blue: 0.42)
    private let corkLightColor = Color(red: 0.82, green: 0.68, blue: 0.52)
    private let corkDarkColor = Color(red: 0.58, green: 0.44, blue: 0.30)
    private let corkSpotColor = Color(red: 0.50, green: 0.36, blue: 0.22)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base cork color with subtle gradient
                LinearGradient(
                    colors: [
                        corkBaseColor,
                        corkBaseColor.opacity(0.95),
                        corkLightColor.opacity(0.9),
                        corkBaseColor
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Cork texture layer using Canvas
                CorkTextureCanvas(
                    size: geometry.size,
                    grainDensity: grainDensity,
                    corkLightColor: corkLightColor,
                    corkDarkColor: corkDarkColor,
                    corkSpotColor: corkSpotColor
                )

                // Subtle vignette effect for depth
                RadialGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.08)
                    ],
                    center: .center,
                    startRadius: min(geometry.size.width, geometry.size.height) * 0.3,
                    endRadius: max(geometry.size.width, geometry.size.height) * 0.8
                )

                // Very subtle noise overlay for extra texture
                CorkNoiseOverlay()
                    .opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

/// Canvas-based cork texture with organic patterns
private struct CorkTextureCanvas: View {
    let size: CGSize
    let grainDensity: Double
    let corkLightColor: Color
    let corkDarkColor: Color
    let corkSpotColor: Color

    // Use a stable seed based on size to keep pattern consistent
    private var seed: UInt64 {
        UInt64(size.width * 1000 + size.height)
    }

    var body: some View {
        Canvas { context, canvasSize in
            var rng = SeededRandomGenerator(seed: seed)

            // Draw cork pores (darker spots)
            drawCorkPores(
                context: &context,
                size: canvasSize,
                rng: &rng
            )

            // Draw light grain highlights
            drawGrainHighlights(
                context: &context,
                size: canvasSize,
                rng: &rng
            )

            // Draw medium-sized texture variations
            drawTextureVariations(
                context: &context,
                size: canvasSize,
                rng: &rng
            )
        }
    }

    private func drawCorkPores(
        context: inout GraphicsContext,
        size: CGSize,
        rng: inout SeededRandomGenerator
    ) {
        let poreCount = Int(size.width * size.height / 800 * grainDensity)

        for _ in 0..<poreCount {
            let x = rng.nextDouble() * size.width
            let y = rng.nextDouble() * size.height
            let radius = rng.nextDouble() * 2.5 + 0.5
            let opacity = rng.nextDouble() * 0.15 + 0.05

            let path = Path(ellipseIn: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2 * (0.8 + rng.nextDouble() * 0.4),
                height: radius * 2 * (0.8 + rng.nextDouble() * 0.4)
            ))

            context.fill(
                path,
                with: .color(corkSpotColor.opacity(opacity))
            )
        }
    }

    private func drawGrainHighlights(
        context: inout GraphicsContext,
        size: CGSize,
        rng: inout SeededRandomGenerator
    ) {
        let highlightCount = Int(size.width * size.height / 2000 * grainDensity)

        for _ in 0..<highlightCount {
            let x = rng.nextDouble() * size.width
            let y = rng.nextDouble() * size.height
            let width = rng.nextDouble() * 8 + 2
            let height = rng.nextDouble() * 3 + 1
            let rotation = Angle.degrees(rng.nextDouble() * 180)
            let opacity = rng.nextDouble() * 0.12 + 0.03

            var grainContext = context
            grainContext.translateBy(x: x, y: y)
            grainContext.rotate(by: rotation)

            let path = Path(ellipseIn: CGRect(
                x: -width / 2,
                y: -height / 2,
                width: width,
                height: height
            ))

            grainContext.fill(
                path,
                with: .color(corkLightColor.opacity(opacity))
            )
        }
    }

    private func drawTextureVariations(
        context: inout GraphicsContext,
        size: CGSize,
        rng: inout SeededRandomGenerator
    ) {
        let variationCount = Int(size.width * size.height / 5000 * grainDensity)

        for _ in 0..<variationCount {
            let x = rng.nextDouble() * size.width
            let y = rng.nextDouble() * size.height
            let radius = rng.nextDouble() * 15 + 5
            let opacity = rng.nextDouble() * 0.06 + 0.02
            let isDark = rng.nextDouble() > 0.5

            let path = Path(ellipseIn: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2 * (0.6 + rng.nextDouble() * 0.8)
            ))

            context.fill(
                path,
                with: .color(isDark ? corkDarkColor.opacity(opacity) : corkLightColor.opacity(opacity))
            )
        }
    }
}

/// A subtle noise overlay for additional texture
private struct CorkNoiseOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                var rng = SeededRandomGenerator(seed: 42)
                let cellSize: CGFloat = 3

                for x in stride(from: 0, to: size.width, by: cellSize) {
                    for y in stride(from: 0, to: size.height, by: cellSize) {
                        let brightness = rng.nextDouble()
                        let color = Color(white: brightness)

                        let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
    }
}

/// A seeded random number generator for consistent procedural generation
private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        // xorshift64 algorithm
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    mutating func nextDouble() -> Double {
        Double(next() % 10000) / 10000.0
    }
}

// MARK: - Section Label

/// A styled section label that looks good on the cork background
struct CorkboardSectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.black.opacity(0.35))
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
            )
    }
}

// MARK: - Empty State

/// Empty state view styled for the cork background
struct CorkboardEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.8))

            Text("This folder is empty")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            Text("Add documents or subfolders to see them as index cards")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.25))
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        )
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Corkboard Background") {
    CorkboardBackground()
        .frame(width: 800, height: 600)
}

#Preview("Corkboard with Cards") {
    ZStack {
        CorkboardBackground()

        VStack {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .frame(width: 200, height: 150)

                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .frame(width: 200, height: 150)
            }

            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .frame(width: 200, height: 150)

                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .frame(width: 200, height: 150)
            }
        }
        .padding(40)
    }
    .frame(width: 600, height: 500)
}
#endif
