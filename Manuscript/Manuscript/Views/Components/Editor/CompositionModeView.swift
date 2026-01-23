//
//  CompositionModeView.swift
//  Manuscript
//
//  A distraction-free fullscreen writing mode similar to Scrivener's Composition Mode.
//

import SwiftUI
import RichTextKit
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct CompositionModeView: View {
    @ObservedObject var viewModel: DocumentDetailViewModel
    @Binding var isPresented: Bool

    @StateObject private var richTextContext = RichTextContext()
    @State private var showControls = false
    @State private var controlsTimer: Timer?
    @State private var hasInitialized = false

    #if os(macOS)
    @State private var textViewRef: NSTextView? = nil
    @State private var keyMonitor: Any? = nil
    @State private var wasFullScreen = false
    #else
    @State private var textViewRef: UITextView? = nil
    #endif

    // Formatting defaults from settings
    @AppStorage("defaultFontName") private var defaultFontName: String = "Palatino"
    @AppStorage("defaultFontSize") private var defaultFontSize: Double = 16
    @AppStorage("defaultLineSpacing") private var defaultLineSpacing: String = "single"
    @AppStorage("enableParagraphIndent") private var enableParagraphIndent: Bool = true
    @AppStorage("paragraphIndentSize") private var paragraphIndentSize: Double = 24

    // Maximum width for comfortable prose reading
    private let maxProseWidth: CGFloat = 700

    // Soft white text color for reduced eye strain
    private let textColor = Color(white: 0.85)

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
                            .animation(.easeInOut(duration: 0.2), value: showControls)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .frame(height: 60)

                    // Editor area
                    #if os(macOS)
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
                    #else
                    RichTextEditor(
                        text: $viewModel.attributedContent,
                        context: richTextContext,
                        viewConfiguration: { textView in
                            if let uiTextView = textView as? UITextView {
                                configureTextView(uiTextView)
                                DispatchQueue.main.async {
                                    textViewRef = uiTextView
                                }
                            }
                        }
                    )
                    .focusedValue(\.richTextContext, richTextContext)
                    .richTextEditorStyle(RichTextEditorStyle(backgroundColor: .clear))
                    .background(.clear)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, horizontalPadding)
                    #endif

                    // Bottom bar with word count
                    HStack {
                        Spacer()
                        wordCountView
                            .opacity(showControls ? 1 : 0)
                            .animation(.easeInOut(duration: 0.2), value: showControls)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                    .frame(height: 50)
                }
            }
        }
        .onAppear {
            if !hasInitialized {
                setupContext()
                hasInitialized = true
            }
            #if os(macOS)
            setupKeyMonitor()
            enterNativeFullScreen()
            #endif
            // Show controls initially, then hide
            showControls = true
            scheduleHideControls()
        }
        .onDisappear {
            saveContent()
            #if os(macOS)
            removeKeyMonitor()
            exitNativeFullScreen()
            #endif
            controlsTimer?.invalidate()
        }
        #if os(macOS)
        .onContinuousHover { phase in
            switch phase {
            case .active:
                showControls = true
                scheduleHideControls()
            case .ended:
                break
            }
        }
        #else
        .onTapGesture {
            showControls.toggle()
            if showControls {
                scheduleHideControls()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe down to dismiss
                    if value.translation.height > 100 {
                        dismissCompositionMode()
                    }
                }
        )
        #endif
        .preferredColorScheme(.dark)
        #if os(iOS)
        .statusBarHidden(true)
        #endif
    }

    // MARK: - UI Components

    private var closeButton: some View {
        Button {
            dismissCompositionMode()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
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
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.4))
    }

    // MARK: - Setup

    private func setupContext() {
        var contentToSet = viewModel.attributedContent

        if enableParagraphIndent && contentToSet.length > 0 {
            contentToSet = applyParagraphIndent(to: contentToSet)
        }

        richTextContext.setAttributedString(to: contentToSet)
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

    private func applyParagraphIndent(to attributedString: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)
        guard fullRange.length > 0 else { return mutable }

        let string = mutable.string as NSString
        var paragraphStart = 0

        while paragraphStart < string.length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: paragraphStart, length: 0))
            let existingStyle = mutable.attribute(.paragraphStyle, at: paragraphRange.location, effectiveRange: nil) as? NSParagraphStyle
            let newStyle = (existingStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            newStyle.firstLineHeadIndent = CGFloat(paragraphIndentSize)
            mutable.addAttribute(.paragraphStyle, value: newStyle, range: paragraphRange)
            paragraphStart = paragraphRange.location + paragraphRange.length
        }

        return mutable
    }

    // MARK: - Text View Configuration

    #if os(macOS)
    private func configureTextView(_ textView: NSTextView) {
        textView.drawsBackground = false
        textView.enclosingScrollView?.drawsBackground = false
        textView.enclosingScrollView?.backgroundColor = .clear
        textView.insertionPointColor = NSColor(white: 0.85, alpha: 1.0)
        textView.textColor = NSColor(white: 0.85, alpha: 1.0)
    }
    #else
    private func configureTextView(_ textView: UITextView) {
        textView.backgroundColor = .clear
        textView.tintColor = UIColor(white: 0.85, alpha: 1.0)
        textView.textColor = UIColor(white: 0.85, alpha: 1.0)
        textView.keyboardAppearance = .dark
    }
    #endif

    // MARK: - Keyboard Handling (macOS)

    #if os(macOS)
    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // ESC to exit
            if event.keyCode == 53 {
                dismissCompositionMode()
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

    private func enterNativeFullScreen() {
        guard let window = NSApplication.shared.keyWindow else { return }

        // Remember if window was already fullscreen
        wasFullScreen = window.styleMask.contains(.fullScreen)

        // Enter fullscreen if not already
        if !wasFullScreen {
            window.toggleFullScreen(nil)
        }

        // Hide the menu bar and dock
        NSApplication.shared.presentationOptions = [
            .autoHideMenuBar,
            .autoHideDock
        ]
    }

    private func exitNativeFullScreen() {
        // Restore normal presentation options
        NSApplication.shared.presentationOptions = []

        // Exit fullscreen only if we entered it
        if !wasFullScreen, let window = NSApplication.shared.keyWindow {
            if window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }
    #endif

    // MARK: - Helper Methods

    private func focusTextEditor() {
        #if os(macOS)
        if let textView = textViewRef {
            textView.window?.makeFirstResponder(textView)
        }
        #else
        if let textView = textViewRef {
            textView.becomeFirstResponder()
        }
        #endif
    }

    private func saveContent() {
        viewModel.attributedContent = richTextContext.attributedString
        viewModel.saveChanges()
    }

    private func scheduleHideControls() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showControls = false
            }
        }
    }

    private func dismissCompositionMode() {
        saveContent()
        withAnimation(.spring(duration: 0.35)) {
            isPresented = false
        }
    }
}

#if DEBUG
#Preview {
    let docItem = ManuscriptDocument.Document(
        title: "Sample Document",
        notes: "Sample notes",
        content: "Sample content with some text to preview the composition mode. This is a longer paragraph to see how the text looks in the distraction-free writing environment."
    )
    let viewModel = DocumentViewModel()
    return CompositionModeView(
        viewModel: DocumentDetailViewModel(document: docItem, documentViewModel: viewModel),
        isPresented: .constant(true)
    )
}
#endif
