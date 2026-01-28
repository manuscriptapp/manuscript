import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

/// A view that displays an image with zoom and pan capabilities
struct ImagePreviewView: View {
    let mediaItem: ManuscriptDocument.MediaItem
    @ObservedObject var assetManager: AssetManager

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 5.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(white: 0.1)
                    .ignoresSafeArea()

                if let image = assetManager.loadImage(for: mediaItem) {
                    #if canImport(AppKit)
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                        .onTapGesture(count: 2) {
                            resetZoom()
                        }
                    #else
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .gesture(dragGesture)
                        .onTapGesture(count: 2) {
                            resetZoom()
                        }
                    #endif
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("Unable to load image")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    zoomIn()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Zoom In")

                Button {
                    zoomOut()
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Zoom Out")

                Button {
                    resetZoom()
                } label: {
                    Image(systemName: "1.magnifyingglass")
                }
                .help("Reset Zoom")
            }
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale = min(max(scale * delta, minScale), maxScale)
            }
            .onEnded { _ in
                lastScale = 1.0
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func zoomIn() {
        withAnimation {
            scale = min(scale * 1.5, maxScale)
        }
    }

    private func zoomOut() {
        withAnimation {
            scale = max(scale / 1.5, minScale)
        }
    }

    private func resetZoom() {
        withAnimation {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

#if DEBUG
#Preview {
    ImagePreviewView(
        mediaItem: ManuscriptDocument.MediaItem(
            title: "Test Image",
            mediaType: .image,
            filename: "test.png",
            originalFilename: "test.png"
        ),
        assetManager: AssetManager()
    )
}
#endif
