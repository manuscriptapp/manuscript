//
//  FindReplaceBar.swift
//  Manuscript
//
//  Platform-adaptive find & replace UI overlay
//

import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// A find & replace bar that works on both iOS and macOS
struct FindReplaceBar: View {
    @ObservedObject var viewModel: FindReplaceViewModel
    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            macOSBar
            #else
            iOSBar
            #endif
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    // MARK: - macOS Layout

    #if os(macOS)
    private var macOSBar: some View {
        VStack(spacing: 6) {
            // Find row
            HStack(spacing: 8) {
                // Search field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    TextField("Find", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isSearchFieldFocused)
                        .onSubmit {
                            viewModel.navigateNext()
                        }

                    // Match count
                    if !viewModel.searchText.isEmpty {
                        Text(viewModel.matchCountDisplay)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize()
                    }

                    // Clear button
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .frame(minWidth: 200, maxWidth: 300)

                // Navigation buttons
                HStack(spacing: 2) {
                    Button {
                        viewModel.navigatePrevious()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)

                    Button {
                        viewModel.navigateNext()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)
                }

                // Case-sensitive toggle
                Toggle(isOn: $viewModel.isCaseSensitive) {
                    Text("Aa")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                .toggleStyle(.button)
                .help("Case Sensitive")

                Spacer()

                // Replace mode toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        viewModel.isReplaceMode.toggle()
                    }
                } label: {
                    Image(systemName: viewModel.isReplaceMode ? "chevron.up.chevron.down" : "arrow.left.arrow.right")
                        .font(.system(size: 12))
                }
                .buttonStyle(.bordered)
                .help(viewModel.isReplaceMode ? "Hide Replace" : "Show Replace")

                // Close button
                Button {
                    viewModel.hide()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape, modifiers: [])
            }

            // Replace row (when in replace mode)
            if viewModel.isReplaceMode {
                HStack(spacing: 8) {
                    // Replace field
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))

                        TextField("Replace", text: $viewModel.replaceText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .onSubmit {
                                viewModel.replaceCurrent()
                            }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .frame(minWidth: 200, maxWidth: 300)

                    // Replace buttons
                    Button("Replace") {
                        viewModel.replaceCurrent()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)

                    Button("Replace All") {
                        viewModel.replaceAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
    #endif

    // MARK: - iOS Layout

    #if os(iOS)
    private var iOSBar: some View {
        VStack(spacing: 8) {
            // Find row
            HStack(spacing: 8) {
                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))

                    TextField("Find", text: $viewModel.searchText)
                        .font(.system(size: 15))
                        .focused($isSearchFieldFocused)
                        .submitLabel(.search)
                        .onSubmit {
                            viewModel.navigateNext()
                        }

                    if !viewModel.searchText.isEmpty {
                        Text(viewModel.matchCountDisplay)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize()

                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)

                // Navigation and close
                HStack(spacing: 4) {
                    Button {
                        viewModel.navigatePrevious()
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(viewModel.matches.isEmpty)

                    Button {
                        viewModel.navigateNext()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .disabled(viewModel.matches.isEmpty)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: 8))

                // Options menu
                Menu {
                    Toggle(isOn: $viewModel.isCaseSensitive) {
                        Label("Case Sensitive", systemImage: "textformat")
                    }

                    Divider()

                    Toggle(isOn: $viewModel.isReplaceMode) {
                        Label("Find & Replace", systemImage: "arrow.left.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                }

                // Close button
                Button {
                    viewModel.hide()
                } label: {
                    Text("Done")
                        .fontWeight(.medium)
                }
            }

            // Replace row (when in replace mode)
            if viewModel.isReplaceMode {
                HStack(spacing: 8) {
                    // Replace field
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14))

                        TextField("Replace", text: $viewModel.replaceText)
                            .font(.system(size: 15))
                            .submitLabel(.done)
                            .onSubmit {
                                viewModel.replaceCurrent()
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)

                    Button("Replace") {
                        viewModel.replaceCurrent()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)

                    Button("All") {
                        viewModel.replaceAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.matches.isEmpty)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.bar)
    }
    #endif
}

// MARK: - Preview

#if DEBUG
#Preview("Find Bar") {
    VStack {
        FindReplaceBar(viewModel: FindReplaceViewModel())
        Spacer()
    }
}

#Preview("Find & Replace Bar") {
    VStack {
        FindReplaceBar(viewModel: {
            let vm = FindReplaceViewModel()
            vm.isReplaceMode = true
            return vm
        }())
        Spacer()
    }
}
#endif
