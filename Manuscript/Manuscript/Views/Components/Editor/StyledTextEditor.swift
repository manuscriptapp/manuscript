import SwiftUI

struct PlainTextEditor: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .font(.body)
    }
}

struct BorderedTextEditor: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    var backgroundColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.05)
        } else {
            #if os(macOS)
            return Color(nsColor: .controlBackgroundColor)
            #else
            return Color(uiColor: .systemBackground)
            #endif
        }
    }
    
    var borderColor: Color {
        if colorScheme == .dark {
            return Color.gray.opacity(0.3)
        } else {
            return Color.black.opacity(0.15)
        }
    }
    
    var innerShadowColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.2)
        } else {
            return Color.black.opacity(0.2)
        }
    }
    
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .font(.body)
            .padding(.horizontal, 5)
            .padding(.vertical, 4)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                    
                    // Top inner shadow
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                        .offset(y: 0.5)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .black.opacity(0.5), location: 0),
                                    .init(color: .clear, location: 0.2)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    // Bottom inner highlight/shadow
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(innerShadowColor, lineWidth: 1)

                        .offset(y: -0.5)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0.8),
                                    .init(color: .black, location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .frame(minHeight: 100)
    }
}


extension View {
    func plainTextEditor() -> some View {
        modifier(PlainTextEditor())
    }
    
    func borderedTextEditor() -> some View {
        modifier(BorderedTextEditor())
    }
} 
