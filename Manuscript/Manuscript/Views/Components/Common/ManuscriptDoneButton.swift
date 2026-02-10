import SwiftUI

struct ManuscriptDoneButton: View {
    var accessibilityLabel: LocalizedStringKey = "Done"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark")
                .fontWeight(.semibold)
        }
        .manuscriptPrimaryButton()
        .accessibilityLabel(accessibilityLabel)
    }
}
