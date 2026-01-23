import SwiftUI
import MapKit

/// A fullscreen map showing all project locations with pins
struct WorldMapSheet: View {
    let locations: [ManuscriptLocation]
    @Environment(\.dismiss) private var dismiss
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Map(position: $mapCameraPosition) {
                ForEach(locations) { location in
                    Marker(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ))
                    .tint(Color(red: 0.2, green: 0.55, blue: 0.35))
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("World Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        zoomToFitAllLocations()
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .disabled(locations.isEmpty)
                }
            }
            .onAppear {
                zoomToFitAllLocations()
            }
        }
    }

    private func zoomToFitAllLocations() {
        guard !locations.isEmpty else {
            // Default to world view if no locations
            mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
            ))
            return
        }

        if locations.count == 1 {
            // Single location - zoom in reasonably close
            let location = locations[0]
            mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
            return
        }

        // Calculate bounding box for all locations
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        // Add padding to the span
        let latDelta = max((maxLat - minLat) * 1.3, 0.1)
        let lonDelta = max((maxLon - minLon) * 1.3, 0.1)

        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }
}

#if DEBUG
#Preview {
    WorldMapSheet(locations: [
        ManuscriptLocation(name: "New York", latitude: 40.7128, longitude: -74.0060),
        ManuscriptLocation(name: "London", latitude: 51.5074, longitude: -0.1278),
        ManuscriptLocation(name: "Tokyo", latitude: 35.6762, longitude: 139.6503)
    ])
}
#endif
