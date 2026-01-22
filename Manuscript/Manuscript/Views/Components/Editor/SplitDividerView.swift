import SwiftUI

#if os(iOS)
/// Draggable divider for iOS split view
struct SplitDividerView: View {
    @Binding var splitRatio: CGFloat
    let totalHeight: CGFloat

    @State private var isDragging = false

    var body: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 1)

            // Drag handle area
            HStack {
                Spacer()
                // Visual handle indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(uiColor: .tertiaryLabel))
                    .frame(width: 36, height: 4)
                Spacer()
            }
            .frame(height: 20)
            .background(Color(uiColor: .secondarySystemBackground))

            // Bottom border
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 1)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    // Calculate new ratio based on drag position
                    let dragY = value.location.y
                    let currentPrimaryHeight = totalHeight * splitRatio
                    let newPrimaryHeight = currentPrimaryHeight + dragY - 11 // 11 = half of handle height

                    // Calculate new ratio and clamp
                    let newRatio = newPrimaryHeight / totalHeight
                    splitRatio = min(max(newRatio, SplitEditorState.minimumRatio), 1.0 - SplitEditorState.minimumRatio)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .scaleEffect(isDragging ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}

#if DEBUG
struct SplitDividerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Color.blue
                .frame(height: 200)
            SplitDividerView(splitRatio: .constant(0.5), totalHeight: 400)
            Color.green
        }
        .frame(height: 400)
    }
}
#endif
#endif
