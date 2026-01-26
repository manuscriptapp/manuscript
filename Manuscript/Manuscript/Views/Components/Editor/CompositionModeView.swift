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

    // Soft white text color for reduced eye strain
    private let textColor = Color(white: 0.85)

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
                            .animation(.easeInOut(duration: 0.2), value: showControls)
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

            // Apply text colors after textView is configured - use UserDefaults directly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let theme = getThemeFromUserDefaults()
                #if os(macOS)
                if let textView = textViewRef {
                    applyTextColors(to: textView, theme: theme)
                }
                #else
                if let textView = textViewRef {
                    applyTextColors(to: textView, theme: theme)
                }
                #endif
            }
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
        .preferredColorScheme(currentTheme.isLight ? .light : .dark)
        .onChange(of: selectedThemeRaw) { _, _ in
            // Update text colors when theme changes - need slight delay for theme to update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // Update the attributed content with new colors
                let updatedContent = applyTextColorToContent(richTextContext.attributedString)
                richTextContext.setAttributedString(to: updatedContent)

                #if os(macOS)
                if let textView = textViewRef {
                    applyTextColors(to: textView)
                }
                #else
                if let textView = textViewRef {
                    applyTextColors(to: textView)
                    textView.keyboardAppearance = currentTheme.isLight ? .light : .dark
                }
                #endif
            }
        }
        #if os(iOS)
        .statusBarHidden(true)
        #endif
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
            .foregroundStyle(currentTheme.textColor.opacity(0.5))
        }
        .padding(.trailing, 24)
    }

    private var closeButton: some View {
        Button {
            dismissCompositionMode()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 28))
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
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(currentTheme.textColor.opacity(0.5))
    }

    // MARK: - Setup

    private func setupContext() {
        var contentToSet = viewModel.attributedContent

        if enableParagraphIndent && contentToSet.length > 0 {
            contentToSet = applyParagraphIndent(to: contentToSet)
        }

        // Apply correct text color for current theme - read directly from UserDefaults
        // to ensure we have the correct value before SwiftUI fully initializes @AppStorage
        let theme = getThemeFromUserDefaults()
        contentToSet = applyTextColorToContent(contentToSet, forTheme: theme)

        // Update both the context AND viewModel since RichTextEditor binds to viewModel
        richTextContext.setAttributedString(to: contentToSet)
        viewModel.attributedContent = contentToSet

        configureParagraphStyle()
    }

    /// Reads the composition theme directly from UserDefaults to avoid @AppStorage timing issues
    private func getThemeFromUserDefaults() -> CompositionTheme {
        let themeRaw = UserDefaults.standard.string(forKey: "compositionModeTheme") ?? CompositionTheme.teal.rawValue
        return CompositionTheme(rawValue: themeRaw) ?? .teal
    }

    /// Removes foreground color and applies the correct text color for the given theme
    private func applyTextColorToContent(_ attributedString: NSAttributedString, forTheme theme: CompositionTheme? = nil) -> NSAttributedString {
        guard attributedString.length > 0 else { return attributedString }

        let mutable = NSMutableAttributedString(attributedString: attributedString)
        let fullRange = NSRange(location: 0, length: mutable.length)

        // First remove any existing foreground color
        mutable.removeAttribute(.foregroundColor, range: fullRange)

        // Determine which theme to use
        let effectiveTheme = theme ?? currentTheme

        // Then apply the correct color for the theme
        #if os(macOS)
        let textColor: NSColor = effectiveTheme.isLight
            ? NSColor(white: 0.15, alpha: 1.0)
            : NSColor(white: 0.85, alpha: 1.0)
        mutable.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        #else
        let textColor: UIColor = effectiveTheme.isLight
            ? UIColor(white: 0.15, alpha: 1.0)
            : UIColor(white: 0.85, alpha: 1.0)
        mutable.addAttribute(.foregroundColor, value: textColor, range: fullRange)
        #endif

        return mutable
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
    private var compositionTextNSColor: NSColor {
        currentTheme.isLight
            ? NSColor(white: 0.15, alpha: 1.0)
            : NSColor(white: 0.85, alpha: 1.0)
    }

    private func configureTextView(_ textView: NSTextView) {
        textView.drawsBackground = false
        textView.enclosingScrollView?.drawsBackground = false
        textView.enclosingScrollView?.backgroundColor = .clear

        // Apply colors immediately using UserDefaults to get correct theme
        let theme = getThemeFromUserDefaults()
        applyTextColors(to: textView, theme: theme)

        // Also apply after a short delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            applyTextColors(to: textView, theme: getThemeFromUserDefaults())
        }
    }

    private func applyTextColors(to textView: NSTextView, theme: CompositionTheme? = nil) {
        let effectiveTheme = theme ?? currentTheme
        let textColor: NSColor = effectiveTheme.isLight
            ? NSColor(white: 0.15, alpha: 1.0)
            : NSColor(white: 0.85, alpha: 1.0)

        textView.insertionPointColor = textColor
        textView.textColor = textColor

        // Set typing attributes so new text uses correct color
        var typingAttrs = textView.typingAttributes
        typingAttrs[.foregroundColor] = textColor
        textView.typingAttributes = typingAttrs

        // Apply to all existing text
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            textStorage.beginEditing()
            textStorage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: textStorage.length))
            textStorage.endEditing()
        }
    }
    #else
    private var compositionTextUIColor: UIColor {
        currentTheme.isLight
            ? UIColor(white: 0.15, alpha: 1.0)
            : UIColor(white: 0.85, alpha: 1.0)
    }

    private func configureTextView(_ textView: UITextView) {
        let theme = getThemeFromUserDefaults()
        textView.backgroundColor = .clear
        textView.keyboardAppearance = theme.isLight ? .light : .dark

        // Apply colors immediately using UserDefaults to get correct theme
        applyTextColors(to: textView, theme: theme)

        // Also apply after a short delay to ensure content is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            applyTextColors(to: textView, theme: getThemeFromUserDefaults())
        }
    }

    private func applyTextColors(to textView: UITextView, theme: CompositionTheme? = nil) {
        let effectiveTheme = theme ?? currentTheme
        let textColor: UIColor = effectiveTheme.isLight
            ? UIColor(white: 0.15, alpha: 1.0)
            : UIColor(white: 0.85, alpha: 1.0)

        textView.tintColor = textColor
        textView.textColor = textColor

        // Set typing attributes so new text uses correct color
        var typingAttrs = textView.typingAttributes
        typingAttrs[.foregroundColor] = textColor
        textView.typingAttributes = typingAttrs

        // Apply to all existing text
        let textStorage = textView.textStorage
        if textStorage.length > 0 {
            textStorage.beginEditing()
            textStorage.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: textStorage.length))
            textStorage.endEditing()
        }
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
        // Ensure text view commits any pending edits
        #if os(macOS)
        if let textView = textViewRef {
            textView.window?.makeFirstResponder(nil)
            textView.breakUndoCoalescing()

            if let textStorage = textView.textStorage, textStorage.length > 0 {
                let mutableCopy = NSMutableAttributedString(attributedString: textStorage)
                mutableCopy.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutableCopy.length))
                viewModel.attributedContent = mutableCopy
            }
        } else {
            viewModel.attributedContent = richTextContext.attributedString
        }
        #else
        if let textView = textViewRef {
            textView.resignFirstResponder()

            let textStorage = textView.textStorage
            if textStorage.length > 0 {
                let mutableCopy = NSMutableAttributedString(attributedString: textStorage)
                mutableCopy.removeAttribute(.foregroundColor, range: NSRange(location: 0, length: mutableCopy.length))
                viewModel.attributedContent = mutableCopy
            }
        } else {
            viewModel.attributedContent = richTextContext.attributedString
        }
        #endif

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
