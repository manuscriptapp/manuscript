import SwiftUI

struct FormContainerView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                content
            }
            .frame(maxWidth: 600, alignment: .leading)
            .padding()
        }
    }
}

// MARK: - Sheet Form

/// A cross-platform form container for sheets that provides appropriate styling
/// on both macOS (compact VStack layout) and iOS (standard Form)
struct SheetForm<Content: View>: View {
    let title: String
    let cancelAction: () -> Void
    let confirmTitle: String
    let confirmAction: () -> Void
    let isConfirmDisabled: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        cancelAction: @escaping () -> Void,
        confirmTitle: String = "Add",
        confirmAction: @escaping () -> Void,
        isConfirmDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.cancelAction = cancelAction
        self.confirmTitle = confirmTitle
        self.confirmAction = confirmAction
        self.isConfirmDisabled = isConfirmDisabled
        self.content = content
    }

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text(title)
                    .font(.headline)

                Spacer()

                // Invisible spacer to balance the close button
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Content - using Form with grouped style for native appearance
            Form {
                content()
            }
            .formStyle(.grouped)

            Divider()

            // Footer with confirm button only
            HStack {
                Spacer()
                Button(confirmTitle) {
                    confirmAction()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(isConfirmDisabled)
            }
            .padding(16)
        }
        .frame(minWidth: 350, idealWidth: 420, maxWidth: 500)
        .background(.regularMaterial)
    }
    #else
    private var iOSLayout: some View {
        NavigationStack {
            Form {
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmTitle) {
                        confirmAction()
                    }
                    .disabled(isConfirmDisabled)
                }
            }
        }
        .presentationBackground(.regularMaterial)
    }
    #endif
}

// MARK: - Sheet Form Field Components

/// A labeled text field for use in SheetForm
/// Uses standard TextField - Form handles styling on both platforms
struct SheetTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    init(_ label: String, text: Binding<String>, placeholder: String = "") {
        self.label = label
        self._text = text
        self.placeholder = placeholder.isEmpty ? label : placeholder
    }

    var body: some View {
        TextField(label, text: $text, prompt: Text(placeholder))
    }
}

/// A labeled picker for use in SheetForm
/// Uses standard Picker - Form handles styling on both platforms
struct SheetPicker<SelectionValue: Hashable, Content: View>: View {
    let label: String
    @Binding var selection: SelectionValue
    @ViewBuilder let content: () -> Content

    var body: some View {
        Picker(label, selection: $selection) {
            content()
        }
    }
}

#if DEBUG
#Preview {
    FormContainerView {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Sample Field", text: .constant(""))
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: .constant("Sample text"))
                .frame(height: 100)
                .borderedTextEditor()
        }
    }
    .frame(width: 800, height: 400) // Simulating a large screen
}
#endif 