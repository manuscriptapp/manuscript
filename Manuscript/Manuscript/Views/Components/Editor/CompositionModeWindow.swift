//
//  CompositionModeWindow.swift
//  Manuscript
//
//  A dedicated fullscreen window for Composition Mode on macOS.
//  Creates a separate window that covers everything including menu bar.
//

#if os(macOS)
import SwiftUI
import AppKit
import RichTextKit

/// Custom window that can always become key (needed for borderless windows)
private class CompositionModeWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Controller for the composition mode fullscreen window
class CompositionModeWindowController: NSObject {
    static let shared = CompositionModeWindowController()

    private var window: NSWindow?
    private var hostingView: NSHostingView<AnyView>?
    private var fadeView: NSView?

    private override init() {
        super.init()
    }

    /// Shows composition mode with the given view model
    func show(viewModel: DocumentDetailViewModel, onDismiss: @escaping () -> Void) {
        guard window == nil else { return }

        // Get the main screen
        guard let screen = NSScreen.main else { return }

        // Create a borderless fullscreen window (custom subclass to allow key status)
        let window = CompositionModeWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver // Above everything including menu bar
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces, .stationary]

        // Create the SwiftUI content
        let compositionContent = CompositionModeContent(
            viewModel: viewModel,
            onDismiss: { [weak self] in
                self?.dismiss()
                onDismiss()
            }
        )

        let hostingView = NSHostingView(rootView: AnyView(compositionContent))
        hostingView.frame = screen.frame

        // Create a container view for the fade animation
        let containerView = NSView(frame: screen.frame)
        containerView.wantsLayer = true
        containerView.alphaValue = 0

        containerView.addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        window.contentView = containerView

        self.window = window
        self.hostingView = hostingView
        self.fadeView = containerView

        // Hide menu bar and dock
        NSApplication.shared.presentationOptions = [
            .autoHideMenuBar,
            .autoHideDock,
            .fullScreen
        ]

        // Activate the app and show the window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // Animate fade in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            containerView.animator().alphaValue = 1.0
        } completionHandler: { [weak self] in
            // After animation, ensure focus on the text view
            self?.focusTextView()
        }
    }

    /// Finds and focuses the text view inside the hosting view
    private func focusTextView() {
        guard let window = window else { return }

        // Find NSTextView in the view hierarchy
        func findTextView(in view: NSView) -> NSTextView? {
            if let textView = view as? NSTextView {
                return textView
            }
            for subview in view.subviews {
                if let found = findTextView(in: subview) {
                    return found
                }
            }
            return nil
        }

        if let contentView = window.contentView,
           let textView = findTextView(in: contentView) {
            window.makeFirstResponder(textView)
        }
    }

    /// Dismisses composition mode
    func dismiss() {
        guard let window = window, let fadeView = fadeView else { return }

        // Animate fade out
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            fadeView.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            // Restore normal presentation
            NSApplication.shared.presentationOptions = []

            // Close the window
            window.orderOut(nil)
            self?.window = nil
            self?.hostingView = nil
            self?.fadeView = nil
        }
    }
}

/// The actual composition mode content view
private struct CompositionModeContent: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    let onDismiss: () -> Void

    @StateObject private var richTextContext = RichTextContext()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var hasInitialized = false
    @State private var textViewRef: NSTextView? = nil
    @State private var keyMonitor: Any? = nil
    @State private var contentOpacity: Double = 0

    // Theme selection (persisted)
    @AppStorage("compositionModeTheme") private var selectedThemeRaw: String = CompositionTheme.teal.rawValue

    private var currentTheme: CompositionTheme {
        CompositionTheme(rawValue: selectedThemeRaw) ?? .teal
    }

    // Formatting defaults from settings
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"
    @AppStorage("enableParagraphIndent") private var enableParagraphIndent: Bool = true
    @AppStorage("paragraphIndentSize") private var paragraphIndentSize: Double = 24

    // Maximum width for comfortable prose reading
    private let maxProseWidth: CGFloat = 700

    var body: some View {
        ZStack {
            // Background with vignette
            CompositionModeBackground(theme: currentTheme)
                .animation(.easeInOut(duration: 0.5), value: currentTheme)

            // Main content area
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let horizontalPadding = max(48, (availableWidth - maxProseWidth) / 2)

                VStack(spacing: 0) {
                    // Top spacer with theme and close buttons
                    HStack {
                        Spacer()
                        themeButton
                            .opacity(showControls ? 1 : 0)
                        closeButton
                            .opacity(showControls ? 1 : 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .frame(height: 70)

                    // Editor area
                    HStack(spacing: 0) {
                        // Left margin - clickable to focus
                        Color.clear
                            .frame(width: horizontalPadding)
                            .contentShape(Rectangle())
                            .onTapGesture { focusTextEditor() }

                        // Center - the editor
                        RichTextEditor(
                            text: $viewModel.attributedContent,
                            context: richTextContext,
                            viewConfiguration: { textView in
                                if let nsTextView = textView as? NSTextView {
                                    configureTextView(nsTextView)
                                    DispatchQueue.main.async {
                                        textViewRef = nsTextView
                                    }
                                }
                            }
                        )
                        .focusedValue(\.richTextContext, richTextContext)
                        .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
                        .background(.clear)
                        .scrollContentBackground(.hidden)
                        .frame(maxWidth: maxProseWidth)

                        // Right margin - clickable to focus
                        Color.clear
                            .frame(width: horizontalPadding)
                            .contentShape(Rectangle())
                            .onTapGesture { focusTextEditor() }
                    }

                    // Bottom bar with word count
                    HStack {
                        Spacer()
                        wordCountView
                            .opacity(showControls ? 1 : 0)
                        Spacer()
                    }
                    .padding(.bottom, 24)
                    .frame(height: 60)
                }
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            if !hasInitialized {
                setupContext()
                hasInitialized = true
            }
            setupKeyMonitor()

            // Animate content in after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.4)) {
                    contentOpacity = 1
                }
            }

            // Focus the editor after it's visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusTextEditor()
            }

            // Show controls initially, then hide
            scheduleHideControls()
        }
        .onDisappear {
            saveContent()
            removeKeyMonitor()
            controlsTimer?.invalidate()
        }
        .onContinuousHover { phase in
            switch phase {
            case .active:
                withAnimation(.easeOut(duration: 0.2)) {
                    showControls = true
                }
                scheduleHideControls()
            case .ended:
                break
            }
        }
        .preferredColorScheme(currentTheme.isLight ? .light : .dark)
        .onChange(of: selectedThemeRaw) { _, _ in
            // Update text colors when theme changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [self] in
                if let textView = textViewRef {
                    // Update the content with new colors
                    let theme = getThemeFromUserDefaults()
                    applyTextColors(to: textView, theme: theme)

                    // Also update the attributed content
                    if let textStorage = textView.textStorage, textStorage.length > 0 {
                        let textColor: NSColor = theme.isLight
                            ? NSColor(white: 0.15, alpha: 1.0)
                            : NSColor(white: 0.85, alpha: 1.0)
                        textStorage.beginEditing()
                        textStorage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: textStorage.length))
                        textStorage.endEditing()
                    }
                }
            }
        }
    }

    // MARK: - UI Components

    private var themeButton: some View {
        Menu {
            Section("Dark") {
                ForEach(CompositionTheme.darkThemes) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedThemeRaw = theme.rawValue
                        }
                    } label: {
                        Label(theme.rawValue, systemImage: theme.iconName)
                    }
                }
            }
            Section("Light") {
                ForEach(CompositionTheme.lightThemes) { theme in
                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedThemeRaw = theme.rawValue
                        }
                    } label: {
                        Label(theme.rawValue, systemImage: theme.iconName)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: currentTheme.iconName)
                    .font(.system(size: 12, weight: .medium))
                Text(currentTheme.rawValue)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(currentTheme.isLight ? Color.black : Color.white)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .padding(.trailing, 24)
    }

    private var closeButton: some View {
        Button {
            dismissWithAnimation()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(currentTheme.textColor.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .help("Exit Composition Mode (ESC)")
    }

    private var wordCountView: some View {
        let wordCount = viewModel.editedContent
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count

        return Text("\(wordCount) words")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(currentTheme.textColor.opacity(0.5))
    }

    // MARK: - Setup

    /// Reads the composition theme directly from UserDefaults to avoid @AppStorage timing issues
    private func getThemeFromUserDefaults() -> CompositionTheme {
        let themeRaw = UserDefaults.standard.string(forKey: "compositionModeTheme") ?? CompositionTheme.teal.rawValue
        return CompositionTheme(rawValue: themeRaw) ?? .teal
    }

    private func setupContext() {
        var contentToSet = viewModel.attributedContent

        // Apply correct text color for current theme - read directly from UserDefaults
        let theme = getThemeFromUserDefaults()
        if contentToSet.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: contentToSet)
            let fullRange = NSRange(location: 0, length: mutable.length)
            mutable.removeAttribute(.foregroundColor, range: fullRange)

            let textColor: NSColor = theme.isLight
                ? NSColor(white: 0.15, alpha: 1.0)
                : NSColor(white: 0.85, alpha: 1.0)
            mutable.addAttribute(.foregroundColor, value: textColor, range: fullRange)
            contentToSet = mutable
        }

        richTextContext.setAttributedString(to: contentToSet)
        viewModel.attributedContent = contentToSet
        configureParagraphStyle()
    }

    private func configureParagraphStyle() {
        if enableParagraphIndent {
            let indentBinding = richTextContext.paragraphStyleValueBinding(for: \.firstLineHeadIndent)
            indentBinding.wrappedValue = CGFloat(paragraphIndentSize)
        }

        let lineSpacingMultiplier: CGFloat = switch defaultLineSpacing {
        case "1.15": 1.15
        case "1.5": 1.5
        case "double": 2.0
        default: 1.0
        }
        let lineSpacingBinding = richTextContext.paragraphStyleValueBinding(for: \.lineSpacing)
        lineSpacingBinding.wrappedValue = lineSpacingMultiplier * 6
    }

    // MARK: - Text View Configuration

    private var compositionTextNSColor: NSColor {
        currentTheme.isLight
            ? NSColor(white: 0.15, alpha: 1.0)
            : NSColor(white: 0.85, alpha: 1.0)
    }

    private func configureTextView(_ textView: NSTextView) {
        textView.drawsBackground = false
        textView.enclosingScrollView?.drawsBackground = false
        textView.enclosingScrollView?.backgroundColor = .clear

        // Apply colors using UserDefaults to get correct theme
        let theme = getThemeFromUserDefaults()
        applyTextColors(to: textView, theme: theme)

        // Also apply after a delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [self] in
            applyTextColors(to: textView, theme: getThemeFromUserDefaults())
        }
    }

    private func applyTextColors(to textView: NSTextView, theme: CompositionTheme? = nil) {
        let effectiveTheme = theme ?? getThemeFromUserDefaults()
        let textColor: NSColor = effectiveTheme.isLight
            ? NSColor(white: 0.15, alpha: 1.0)
            : NSColor(white: 0.85, alpha: 1.0)

        // Cursor color
        textView.insertionPointColor = textColor

        // Set text color for existing content
        textView.textColor = textColor

        // Configure typing attributes so new text is visible
        let font = NSFont(name: defaultFontName, size: CGFloat(defaultFontSize)) ?? NSFont.systemFont(ofSize: CGFloat(defaultFontSize))
        textView.typingAttributes = [
            .foregroundColor: textColor,
            .font: font
        ]

        // Apply color to all existing text
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            textStorage.beginEditing()
            textStorage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: textStorage.length))
            textStorage.endEditing()
        }
    }

    // MARK: - Keyboard Handling

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // ESC to exit
            if event.keyCode == 53 {
                dismissWithAnimation()
                return nil
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    // MARK: - Helper Methods

    private func focusTextEditor() {
        guard let textView = textViewRef else { return }
        // Make the window key and the text view first responder
        textView.window?.makeKey()
        textView.window?.makeFirstResponder(textView)
    }

    private func saveContent() {
        // Ensure text view commits any pending edits
        if let textView = textViewRef {
            // End any current editing session
            textView.window?.makeFirstResponder(nil)
            textView.breakUndoCoalescing()

            // Read directly from the text view's text storage
            if let textStorage = textView.textStorage, textStorage.length > 0 {
                let mutableCopy = NSMutableAttributedString(attributedString: textStorage)
                // Remove composition mode text color before saving
                mutableCopy.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutableCopy.length))
                viewModel.attributedContent = mutableCopy
            }
        } else {
            // Fallback to richTextContext
            viewModel.attributedContent = richTextContext.attributedString
        }

        viewModel.saveChanges()
    }

    private func scheduleHideControls() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.4)) {
                showControls = false
            }
        }
    }

    private func dismissWithAnimation() {
        saveContent()
        withAnimation(.easeIn(duration: 0.2)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onDismiss()
        }
    }
}
#endif
