import SwiftUI
import SwiftData
import Foundation
import Combine

@MainActor
final class AppViewModel: ObservableObject {
    @Published var detailSelection: DetailSelection? = nil
    @Published var isAddBookSheetPresented = false
    @Published var isAddActSheetPresented = false
    @Published var isAddChapterSheetPresented = false
    @Published var isAddCharacterSheetPresented = false
    @Published var isAddLocationSheetPresented = false
    @Published var showOnboarding = false
    
    let manuscriptViewModel: ManuscriptViewModel
    @AppStorage("hasSeenOnboarding") private var _hasSeenOnboarding = false
    
    var hasSeenOnboarding: Bool {
        _hasSeenOnboarding
    }
    
    init(document: ManuscriptDocument) {
        self.manuscriptViewModel = ManuscriptViewModel(document: document)
        
        // Set default detail selection if needed
        self.detailSelection = .projectInfo
    }
    
    func checkOnboarding() {
        if !_hasSeenOnboarding {
            showOnboarding = true
        }
    }
    
    func onboardingCompleted() {
        _hasSeenOnboarding = true
        showOnboarding = false
    }
} 