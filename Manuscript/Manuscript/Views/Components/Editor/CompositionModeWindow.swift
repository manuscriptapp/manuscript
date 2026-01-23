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
            CompositionModeBackground()

            // Main content area
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let horizontalPadding = max(48, (availableWidth - maxProseWidth) / 2)

                VStack(spacing: 0) {
                    // Top spacer with close button area
                    HStack {
                        Spacer()
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
        .preferredColorScheme(.dark)
    }

    // MARK: - UI Components

    private var closeButton: some View {
        Button {
            dismissWithAnimation()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.white.opacity(0.6))
                .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .help("Exit Composition Mode (ESC)")
    }

    private var wordCountView: some View {
        let wordCount = viewModel.editedContent
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count

        return Text("\(wordCount) words")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.5))
    }

    // MARK: - Setup

    private func setupContext() {
        richTextContext.setAttributedString(to: viewModel.attributedContent)
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

    private let compositionTextColor = NSColor(white: 0.85, alpha: 1.0)

    private func configureTextView(_ textView: NSTextView) {
        textView.drawsBackground = false
        textView.enclosingScrollView?.drawsBackground = false
        textView.enclosingScrollView?.backgroundColor = .clear

        // Light cursor color
        textView.insertionPointColor = compositionTextColor

        // Set text color for existing content
        textView.textColor = compositionTextColor

        // Configure typing attributes so new text is visible
        let font = NSFont(name: defaultFontName, size: CGFloat(defaultFontSize)) ?? NSFont.systemFont(ofSize: CGFloat(defaultFontSize))
        textView.typingAttributes = [
            .foregroundColor: compositionTextColor,
            .font: font
        ]

        // Apply light color to all existing text
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            textStorage.addAttribute(.foregroundColor, value: compositionTextColor, range: NSRange(location: 0, length: textStorage.length))
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
        viewModel.attributedContent = richTextContext.attributedString
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
