import SwiftUI

// MARK: - Legacy view (deprecated)
// This view is no longer used in the main app flow.
// The app now uses ManuscriptProjectView with DocumentGroup.

struct MacOSContentView: View {
    @ObservedObject var manuscriptViewModel: ManuscriptViewModel
    @Binding var detailSelection: DetailSelection?
    @Binding var isAddBookSheetPresented: Bool

    var body: some View {
        ContentUnavailableView(
            "Legacy View",
            systemImage: "exclamationmark.triangle",
            description: Text("This view has been deprecated. Please use ManuscriptProjectView instead.")
        )
    }
}
