import SwiftUI
import MapKit

/// A fullscreen map showing all project locations with pins and a bottom sheet listing locations
struct WorldMapSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedLocation: ManuscriptLocation?
    @State private var showLocationsList: Bool = true
    @State private var showLookAround: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var sheetDetent: PresentationDetent = .fraction(0.25)

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
            // Show either map or Look Around view
            if showLookAround, lookAroundScene != nil {
                LookAroundPreview(scene: $lookAroundScene)
                    .ignoresSafeArea()
                    .onChange(of: lookAroundScene) { _, newValue in
                        // Exit streetview mode when user dismisses via built-in X button
                        if newValue == nil {
                            showLookAround = false
                        }
                    }
            } else {
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

                // Top toolbar overlay - only show when NOT in streetview
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())

                        Spacer()

                        // Look Around toggle - visible when location selected with scene available
                        if selectedLocation != nil && lookAroundScene != nil {
                            Button {
                                showLookAround = true
                                sheetDetent = .fraction(0.25) // Minimize sheet when entering streetview
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "binoculars.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding()
                    .padding(.top, 44) // Safe area

                    Spacer()
                }
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
            .presentationDetents([.medium, .large, .fraction(0.25)], selection: $sheetDetent)
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
        showLookAround = false // Reset to map view when selecting new location
        // Only expand sheet to medium if it's at the smallest detent
        if sheetDetent == .fraction(0.25) {
            sheetDetent = .medium
        }
        withAnimation(.easeInOut(duration: 0.5)) {
            mapCameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
        // Fetch Look Around scene for the selected location
        fetchLookAroundScene(for: location)
    }

    private func fetchLookAroundScene(for location: ManuscriptLocation) {
        lookAroundScene = nil
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            do {
                let scene = try await request.scene
                await MainActor.run {
                    lookAroundScene = scene
                }
            } catch {
                // Look Around not available for this location
                await MainActor.run {
                    lookAroundScene = nil
                }
            }
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
        VStack(spacing: 0) {
            // Custom header
            Text("Locations")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            Divider()

            List(locations) { location in
                NavigationLink {
                    LocationDetailView(viewModel: viewModel, location: location)
                        .onAppear {
                            // Select location when navigating to detail view
                            onLocationSelected(location)
                        }
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

                        // Map selection button
                        Button {
                            onLocationSelected(location)
                        } label: {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationBarHidden(true)
    }
}

#if DEBUG
#Preview {
    // Preview requires a DocumentViewModel, so we can't easily preview this
    Text("WorldMapSheet Preview - requires DocumentViewModel")
}
#endif
