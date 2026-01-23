import SwiftUI
import MapKit

/// A fullscreen map showing all project locations with pins and a bottom sheet listing locations
struct WorldMapSheet: View {
    let locations: [ManuscriptLocation]
    @Environment(\.dismiss) private var dismiss
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedLocation: ManuscriptLocation?
    @State private var showLocationsList: Bool = true

    init(locations: [ManuscriptLocation]) {
        self.locations = locations
        self._mapCameraPosition = State(initialValue: Self.calculateCameraPosition(for: locations))
    }

    private static func calculateCameraPosition(for locations: [ManuscriptLocation]) -> MapCameraPosition {
        guard !locations.isEmpty else {
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
            ))
        }

        if locations.count == 1 {
            let location = locations[0]
            return .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            ))
        }

        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let latDelta = max((maxLat - minLat) * 1.5, 0.5)
        let lonDelta = max((maxLon - minLon) * 1.5, 0.5)

        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }

    private var annotations: [LocationAnnotation] {
        locations.map { location in
            LocationAnnotation(
                id: location.id,
                name: location.name,
                coordinate: CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            )
        }
    }

    var body: some View {
        ZStack {
            // Full screen map
            Map(position: $mapCameraPosition) {
                ForEach(annotations) { annotation in
                    Annotation(annotation.name, coordinate: annotation.coordinate) {
                        ZStack {
                            Circle()
                                .fill(selectedLocation?.id == annotation.id
                                    ? Color.blue
                                    : Color(red: 0.6, green: 0.4, blue: 0.2))
                                .frame(width: 30, height: 30)
                            Image(systemName: "mappin")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            // Top toolbar overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            selectedLocation = nil
                            mapCameraPosition = Self.calculateCameraPosition(for: locations)
                        }
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .disabled(locations.isEmpty)
                }
                .padding()
                .padding(.top, 44) // Safe area

                Spacer()
            }
        }
        .sheet(isPresented: $showLocationsList) {
            LocationsListSheet(
                locations: locations,
                selectedLocation: $selectedLocation,
                onLocationSelected: { location in
                    selectLocation(location)
                }
            )
            .presentationDetents([.medium, .large, .fraction(0.25)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapCameraPosition = Self.calculateCameraPosition(for: locations)
                }
            }
        }
    }

    private func selectLocation(_ location: ManuscriptLocation) {
        selectedLocation = location
        withAnimation(.easeInOut(duration: 0.5)) {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    private struct LocationAnnotation: Identifiable {
        let id: UUID
        let name: String
        let coordinate: CLLocationCoordinate2D
    }
}

// MARK: - Locations List Bottom Sheet

struct LocationsListSheet: View {
    let locations: [ManuscriptLocation]
    @Binding var selectedLocation: ManuscriptLocation?
    let onLocationSelected: (ManuscriptLocation) -> Void

    var body: some View {
        List(locations) { location in
            Button {
                onLocationSelected(location)
            } label: {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(selectedLocation?.id == location.id
                            ? .blue
                            : Color(red: 0.6, green: 0.4, blue: 0.2))
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if selectedLocation?.id == location.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
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
