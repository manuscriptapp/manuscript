import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct WriteTab: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    @State private var isSheetPresented = false
    #if os(iOS)
    @State private var selectionCheckTimer: Timer? = nil
    #endif
    // Add a local state property to track selection range
    @State private var selectionRange: NSRange?
    
    var body: some View {
        VStack {
            ScrollView {
                TextEditor(text: $viewModel.editedContent)
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .plainTextEditor()
                    .padding()
                    .padding(.bottom, 120)
                    .onSelectionChange { selection in
                        handleSelectionChange(selection)
                    }
            }
        }
        .onAppear {
            // Register for additional notifications on appear
            #if os(iOS)
            setupAdditionalNotifications()
            
            // Set up a timer to periodically check for selection on iOS
            selectionCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                checkForActiveSelection()
            }
            #endif
        }
        .onDisappear {
            #if os(iOS)
            // Clean up timer when view disappears
            selectionCheckTimer?.invalidate()
            selectionCheckTimer = nil
            #endif
        }
    }
    
    #if os(iOS)
    private func setupAdditionalNotifications() {
        // Add additional iOS-specific notification observers
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let textView = notification.object as? UITextView {
                checkTextViewSelection(textView)
            }
        }
        
        // Use UITextViewDelegate methods instead of this notification
        // as UITextView doesn't have a selectionDidChangeNotification
        NotificationCenter.default.addObserver(
            forName: UITextView.textDidBeginEditingNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let textView = notification.object as? UITextView {
                checkTextViewSelection(textView)
            }
        }
    }
    
    private func checkTextViewSelection(_ textView: UITextView) {
        let selectedRange = textView.selectedRange
        if selectedRange.length > 0 {
            let selectedText = (textView.text as NSString).substring(with: selectedRange)
            print("iOS Selection detected: \(selectedText) (length: \(selectedText.count))")
            
            // Update the viewModel
            DispatchQueue.main.async {
                viewModel.selectedText = selectedText
                viewModel.hasTextSelection = true
                self.selectionRange = selectedRange
            }
        }
    }
    
    private func checkForActiveSelection() {
        // Find the first responder text view and check its selection
        if let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first,
           let textView = findActiveTextView(in: keyWindow) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                let selectedText = (textView.text as NSString).substring(with: selectedRange)
                print("Timer check detected selection: \(selectedText) (length: \(selectedText.count))")
                
                // Update the viewModel
                DispatchQueue.main.async {
                    viewModel.selectedText = selectedText
                    viewModel.hasTextSelection = true
                    self.selectionRange = selectedRange
                }
            }
        }
    }
    
    private func findActiveTextView(in view: UIView) -> UITextView? {
        // Check if this view is a text view and is first responder
        if let textView = view as? UITextView, textView.isFirstResponder {
            return textView
        }
        
        // Recursively check subviews
        for subview in view.subviews {
            if let textView = findActiveTextView(in: subview) {
                return textView
            }
        }
        
        return nil
    }
    #endif
    
    private func handleSelectionChange(_ selection: NSRange?) {
        if let range = selection, range.length > 0 {
            // Get the selected text
            let nsString = viewModel.editedContent as NSString
            let selectedText = nsString.substring(with: range)
            
            // Debug print
            print("Text selected: \(selectedText) (length: \(selectedText.count), range: \(range))")
            
            // Update the viewModel
            viewModel.selectedText = selectedText
            viewModel.hasTextSelection = true
            self.selectionRange = range
        } else {
            // Clear selection
            if viewModel.hasTextSelection {
                print("Selection cleared")
            }
            viewModel.selectedText = ""
            viewModel.hasTextSelection = false
            self.selectionRange = nil
        }
    }
}

// Extension to add selection change handling to TextEditor
extension View {
    func onSelectionChange(_ action: @escaping (NSRange?) -> Void) -> some View {
        #if os(iOS)
        return self.background(SelectionObserver(onSelectionChange: action))
        #else
        return self.background(SelectionObserver(onSelectionChange: action))
        #endif
    }
}

#if os(iOS)
// iOS implementation
struct SelectionObserver: UIViewRepresentable {
    let onSelectionChange: (NSRange?) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // The coordinator is already created by SwiftUI, no need to create it again
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let textView = findTextView(in: uiView.superview) {
                let selectedRange = textView.selectedRange
                if selectedRange.length > 0 {
                    print("iOS updateUIView detected selection: \(selectedRange)")
                    onSelectionChange(selectedRange)
                }
                
                // Add direct observer to this specific text view if not already added
                if !context.coordinator.isObserving {
                    textView.delegate = context.coordinator
                    context.coordinator.isObserving = true
                    context.coordinator.textView = textView
                    
                    // Add tap gesture recognizer to detect taps which might lead to selection
                    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
                    tapGesture.cancelsTouchesInView = false
                    textView.addGestureRecognizer(tapGesture)
                    
                    // Add long press gesture recognizer to detect selection gestures
                    let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
                    longPressGesture.cancelsTouchesInView = false
                    textView.addGestureRecognizer(longPressGesture)
                    
                    // Add direct notification observers for this specific text view
                    // UITextView doesn't have selectionDidChangeNotification, use delegate methods instead
                    NotificationCenter.default.addObserver(
                        context.coordinator,
                        selector: #selector(Coordinator.textViewDidChange(_:)),
                        name: UITextView.textDidChangeNotification,
                        object: textView
                    )
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelectionChange: onSelectionChange)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var onSelectionChange: (NSRange?) -> Void
        var isObserving = false
        var textView: UITextView?
        
        init(onSelectionChange: @escaping (NSRange?) -> Void) {
            self.onSelectionChange = onSelectionChange
            super.init()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                let text = (textView.text as NSString).substring(with: selectedRange)
                print("iOS delegate detected selection: \(text) (length: \(text.count))")
                onSelectionChange(selectedRange)
            } else {
                onSelectionChange(nil)
            }
        }
        
        @objc func textViewDidChange(_ notification: Notification) {
            if let textView = notification.object as? UITextView {
                let selectedRange = textView.selectedRange
                if selectedRange.length > 0 {
                    let text = (textView.text as NSString).substring(with: selectedRange)
                    print("iOS notification detected selection: \(text) (length: \(text.count))")
                    onSelectionChange(selectedRange)
                } else {
                    onSelectionChange(nil)
                }
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            // Check for selection after a short delay to allow iOS to update the selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                if let textView = gesture.view as? UITextView {
                    let selectedRange = textView.selectedRange
                    if selectedRange.length > 0 {
                        let text = (textView.text as NSString).substring(with: selectedRange)
                        print("iOS tap gesture detected selection: \(text) (length: \(text.count))")
                        self?.onSelectionChange(selectedRange)
                    }
                }
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began || gesture.state == .ended {
                // Check for selection after a short delay to allow iOS to update the selection
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    if let textView = gesture.view as? UITextView {
                        let selectedRange = textView.selectedRange
                        if selectedRange.length > 0 {
                            let text = (textView.text as NSString).substring(with: selectedRange)
                            print("iOS long press detected selection: \(text) (length: \(text.count))")
                            self?.onSelectionChange(selectedRange)
                        }
                    }
                }
            }
        }
    }
    
    private func findTextView(in view: UIView?) -> UITextView? {
        if let view = view {
            for subview in view.subviews {
                if let textView = subview as? UITextView {
                    return textView
                }
                if let textView = findTextView(in: subview) {
                    return textView
                }
            }
        }
        return nil
    }
}
#else
// macOS implementation
struct SelectionObserver: NSViewRepresentable {
    let onSelectionChange: (NSRange?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        // Add notification observers for selection changes
        NotificationCenter.default.addObserver(forName: NSText.didChangeNotification, object: nil, queue: .main) { notification in
            if let textView = notification.object as? NSTextView {
                let selectedRange = textView.selectedRange()
                if selectedRange.length > 0 {
                    onSelectionChange(selectedRange)
                } else {
                    onSelectionChange(nil)
                }
            }
        }
        
        // Add observer for selection changes
        NotificationCenter.default.addObserver(forName: NSTextView.didChangeSelectionNotification, object: nil, queue: .main) { notification in
            if let textView = notification.object as? NSTextView {
                let selectedRange = textView.selectedRange()
                if selectedRange.length > 0 {
                    onSelectionChange(selectedRange)
                } else {
                    onSelectionChange(nil)
                }
            }
        }
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Check for current selection
        DispatchQueue.main.async {
            if let textView = findTextView(in: nsView.superview) {
                let selectedRange = textView.selectedRange()
                if selectedRange.length > 0 {
                    onSelectionChange(selectedRange)
                } else {
                    onSelectionChange(nil)
                }
            }
        }
    }
    
    private func findTextView(in view: NSView?) -> NSTextView? {
        if let view = view {
            for subview in view.subviews {
                if let textView = subview as? NSTextView {
                    return textView
                }
                if let textView = findTextView(in: subview) {
                    return textView
                }
            }
        }
        return nil
    }
}
#endif

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content"
    )
    let viewModel = DocumentViewModel()
    return WriteTab(viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel))
}
#endif 
