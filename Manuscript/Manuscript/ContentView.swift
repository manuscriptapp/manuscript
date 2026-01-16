import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var document: ManuscriptDocument
    
    init(document: ManuscriptDocument) {
        self.document = document
        _viewModel = StateObject(wrappedValue: AppViewModel(document: document))
    }
    
    var body: some View {
        Group {
#if os(iOS)
            IOSContentView(
                manuscriptViewModel: viewModel.manuscriptViewModel,
                detailSelection: $viewModel.detailSelection,
                isAddBookSheetPresented: $viewModel.isAddBookSheetPresented
            )
#else
            MacOSContentView(
                manuscriptViewModel: viewModel.manuscriptViewModel,
                detailSelection: $viewModel.detailSelection,
                isAddBookSheetPresented: $viewModel.isAddBookSheetPresented
            )
#endif
        }
//        .sheet(isPresented: $viewModel.isAddBookSheetPresented) {
//            NewProjectSheet(manuscriptViewModel: viewModel.manuscriptViewModel)
//        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled(!viewModel.hasSeenOnboarding)
                .onDisappear {
                    viewModel.onboardingCompleted()
                }
        }
        .onAppear {
            viewModel.checkOnboarding()
        }
    }
}

extension Color {
    static var adaptiveBackground: Color {
        #if os(iOS)
        return Color(UIColor.systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor) // Closest macOS equivalent
        #endif
    }
}

extension Color {
    static var inputBorder: Color {
        #if os(iOS)
        return Color(UIColor.tertiarySystemFill)
        #else
        return Color(NSColor.separatorColor) // macOS doesn't have `tertiarySystemFill`
        #endif
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(document: ManuscriptDocument.preview(title: "Preview Document", author: "Preview Author"))
            .previewDisplayName("With Document")
    }
}
#endif

