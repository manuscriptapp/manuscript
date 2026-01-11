import SwiftUI
import SwiftData

struct ReadContentView: View {
    let item: FolderContentBuilder.TreeItem
    let isRoot: Bool
    
    init(item: FolderContentBuilder.TreeItem, isRoot: Bool = false) {
        self.item = item
        self.isRoot = isRoot
    }
    
    var body: some View {
        Group {
            switch item {
            case .folder(let folder, let children):
                if !children.isEmpty {
                    if isRoot {
                        ForEach(children) { child in
                            ReadContentView(item: child)
                        }
                    } else {
                        Section {
                            ForEach(children) { child in
                                ReadContentView(item: child)
                            }
                        } header: {
                            Text(folder.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .textCase(nil)
                                .foregroundStyle(.primary)
                                .padding(.top, 8)
                        }
                    }
                }
                
            case .document(let document):
                VStack(alignment: .leading, spacing: 12) {
                    Text(document.title)
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Text(document.content)
                        .font(.body)
                        .lineSpacing(6)
                }
                .padding(.bottom, 16)
            }
        }
    }
}

