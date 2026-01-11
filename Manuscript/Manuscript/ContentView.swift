import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel: AppViewModel
    @State private var document: LiteratiDocument
    
    init(document: LiteratiDocument) {
        self.document = document
        _viewModel = StateObject(wrappedValue: AppViewModel(document: document))
    }
    
    var body: some View {
        Group {
#if os(iOS)
            IOSContentView(
                literatiViewModel: viewModel.literatiViewModel,
                detailSelection: $viewModel.detailSelection,
                isAddBookSheetPresented: $viewModel.isAddBookSheetPresented
            )
#else
            MacOSContentView(
                literatiViewModel: viewModel.literatiViewModel,
                detailSelection: $viewModel.detailSelection,
                isAddBookSheetPresented: $viewModel.isAddBookSheetPresented
            )
#endif
        }
//        .sheet(isPresented: $viewModel.isAddBookSheetPresented) {
//            NewProjectSheet(literatiViewModel: viewModel.literatiViewModel)
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
extension LiteratiDocument {
    // Convenience initializer for previews
    convenience init(title: String, author: String) {
        self.init()
        self.title = title
        self.author = author
    }
}

#Preview("With Document") {
    let document = LiteratiDocument(title: "Preview Document", author: "Preview Author")
    ContentView(document: document)
}

#Preview("Empty Document") {
    let document = LiteratiDocument(title: "Empty Document", author: "Preview Author")
    ContentView(document: document)
}
#endif

