import SwiftUI

extension View {
    /// Standard primary action appearance: accent background with white foreground.
    func manuscriptPrimaryButton() -> some View {
        buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .foregroundStyle(.white)
    }
}
