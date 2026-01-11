import SwiftUI

// MARK: - Legacy view (deprecated)
// This view is no longer used in the main app flow.
// The app now uses ManuscriptProjectView with DocumentGroup.

struct BookView: View {
    @Binding var document: ManuscriptDocument
    @ObservedObject var manuscriptViewModel: ManuscriptViewModel
    @Binding var detailSelection: DetailSelection?

    init(document: Binding<ManuscriptDocument>, manuscriptViewModel: ManuscriptViewModel, detailSelection: Binding<DetailSelection?>) {
        self._document = document
        self.manuscriptViewModel = manuscriptViewModel
        self._detailSelection = detailSelection
    }

    var body: some View {
        ContentUnavailableView(
            "Legacy View",
            systemImage: "exclamationmark.triangle",
            description: Text("This view has been deprecated. Please use ManuscriptProjectView instead.")
        )
    }
}
