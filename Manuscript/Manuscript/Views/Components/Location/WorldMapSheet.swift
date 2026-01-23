import SwiftUI
import MapKit

/// A fullscreen map showing all project locations with pins and a bottom sheet listing locations
// TODO: Add streetview toggle/icon to switch between map and streetview at selected location
struct WorldMapSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedLocation: ManuscriptLocation?
    @State private var showLocationsList: Bool = true

    private var locations: [ManuscriptLocation] {
        viewModel.locations
    }

    init(viewModel: DocumentViewModel) {
        self.viewModel = viewModel
        self._mapCameraPosition = State(initialValue: Self.calculateInitialCameraPosition(for: viewModel.locations))
    }

    /// Calculates initial camera position focusing on the densest cluster of locations
    private static func calculateInitialCameraPosition(for locations: [ManuscriptLocation]) -> MapCameraPosition {
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

        // Find the densest cluster - group locations by proximity
        let cluster = findDensestCluster(locations: locations)

        let latitudes = cluster.map { $0.latitude }
        let longitudes = cluster.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        // Keep zoom level reasonable (at least city level, at most country level)
        let latDelta = max(min((maxLat - minLat) * 1.5, 20), 0.5)
        let lonDelta = max(min((maxLon - minLon) * 1.5, 20), 0.5)

        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        ))
    }

    /// Finds the cluster with the most locations using simple geographic binning
    private static func findDensestCluster(locations: [ManuscriptLocation]) -> [ManuscriptLocation] {
        // If all locations fit within a reasonable area (10 degrees), show them all
        let latitudes = locations.map { $0.latitude }
        let longitudes = locations.map { $0.longitude }

        let latSpan = (latitudes.max() ?? 0) - (latitudes.min() ?? 0)
        let lonSpan = (longitudes.max() ?? 0) - (longitudes.min() ?? 0)

        if latSpan <= 15 && lonSpan <= 30 {
            return locations
        }

        // Locations are spread across continents - find the densest region
        // Use a grid-based approach: divide world into 30-degree cells
        let cellSize: Double = 30

        var cells: [String: [ManuscriptLocation]] = [:]

        for location in locations {
            let latCell = Int(floor(location.latitude / cellSize))
            let lonCell = Int(floor(location.longitude / cellSize))
            let key = "\(latCell),\(lonCell)"

            if cells[key] == nil {
                cells[key] = []
            }
            cells[key]?.append(location)
        }

        // Find the cell with the most locations
        let densestCell = cells.max(by: { $0.value.count < $1.value.count })

        return densestCell?.value ?? locations
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

            // Top toolbar overlay - just close button
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
                }
                .padding()
                .padding(.top, 44) // Safe area

                Spacer()
            }
        }
        .sheet(isPresented: $showLocationsList) {
            NavigationStack {
                LocationsListSheet(
                    viewModel: viewModel,
                    locations: locations,
                    selectedLocation: $selectedLocation,
                    onLocationSelected: { location in
                        selectLocation(location)
                    }
                )
            }
            .presentationDetents([.medium, .large, .fraction(0.25)])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    mapCameraPosition = Self.calculateInitialCameraPosition(for: locations)
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
    @ObservedObject var viewModel: DocumentViewModel
    let locations: [ManuscriptLocation]
    @Binding var selectedLocation: ManuscriptLocation?
    let onLocationSelected: (ManuscriptLocation) -> Void

    var body: some View {
        List(locations) { location in
            HStack {
                // Tap to zoom on map
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
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                // Detail button - pushes LocationDetailView
                NavigationLink {
                    LocationDetailView(viewModel: viewModel, location: location)
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
        }
        .listStyle(.plain)
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
#Preview {
    // Preview requires a DocumentViewModel, so we can't easily preview this
    Text("WorldMapSheet Preview - requires DocumentViewModel")
}
#endif
