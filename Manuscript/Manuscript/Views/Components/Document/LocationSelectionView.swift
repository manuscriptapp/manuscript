import SwiftUI
import SwiftData

struct LocationSelectionView: View {
    let locations: [ManuscriptLocation]?
    @Binding var selectedLocations: Set<UUID>
    @Binding var isExpanded: Bool
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                
                List {
                    if let locations = locations {
                        ForEach(locations) { location in
                            Toggle(
                                isOn: Binding(
                                    get: { selectedLocations.contains(location.id) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLocations.insert(location.id)
                                        }
                                        else {
                                            selectedLocations.remove(location.id)
                                        }
                                    }
                                )
                            ) {
                                VStack(alignment: .leading) {
                                    Text(location.name)
                                        .font(.body)
                                    Text("Coordinates: \(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    else {
                        Text("No locations available")
                            .foregroundStyle(.secondary)
                    }
                }
                
#if os(macOS)
                .padding(4)
                .toggleStyle(.checkbox)
#endif
            },
            label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.accent)
                    Text("Locations")
                        .badge(selectedLocations.count)
                }
            }
        )
    }
    
}

#if DEBUG
#Preview {
    LocationSelectionView(
        locations: [
            ManuscriptLocation(name: "Mountain Temple", latitude: 35.6762, longitude: 139.6503),
            ManuscriptLocation(name: "Coastal Village", latitude: 34.7466, longitude: 138.4567)
        ],
        selectedLocations: .constant(Set<UUID>()),
        isExpanded: .constant(true)
    )
}
#endif
