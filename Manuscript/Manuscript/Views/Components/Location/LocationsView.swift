import SwiftUI

struct LocationsView: View {
    @ObservedObject var viewModel: DocumentViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.locations) { location in
                NavigationLink(value: DetailSelection.location(location)) {
                    VStack(alignment: .leading) {
                        Text(location.name)
                            .font(.headline)
                        
                        Text("Coordinates: \(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .contextMenu {
                    Button {
                        viewModel.showRenameAlert(for: location)
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        viewModel.deleteLocation(location)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Locations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addLocation(name: "New Location", latitude: 0, longitude: 0)
                } label: {
                    Label("Add Location", systemImage: "plus")
                }
            }
        }
    }
} 