import SwiftUI
import MapKit

/// A fullscreen map showing all project locations with pins and a bottom sheet listing locations
struct WorldMapView: View {
    @ObservedObject var viewModel: DocumentViewModel
    @State private var mapCameraPosition: MapCameraPosition
    @State private var selectedLocation: ManuscriptLocation?
    @State private var showLocationsList: Bool = true
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showLookAround = false
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
        mapContent
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        mapCameraPosition = Self.calculateInitialCameraPosition(for: locations)
                    }
                }
            }
            .navigationTitle("World Map")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }

    // MARK: - Platform-specific layouts

    @ViewBuilder
    private var mapContent: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    #if os(macOS)
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            // Main map view
            mapView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Inspector sidebar
            if showLocationsList {
                Divider()
                inspectorSidebar
                    .frame(width: 320)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if selectedLocation != nil, lookAroundScene != nil {
                    Button {
                        showLookAround = true
                    } label: {
                        Image(systemName: "binoculars.fill")
                    }
                    .help("Look Around")
                }

                Button {
                    withAnimation {
                        showLocationsList.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.trailing")
                }
                .help("Toggle Locations Panel")
            }
        }
        .sheet(isPresented: $showLookAround) {
            if let scene = lookAroundScene {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Text("Look Around")
                            .font(.headline)
                        Spacer()
                        Text("Static preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Done") {
                            showLookAround = false
                        }
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                    .padding()
                    .background(.bar)

                    LookAroundPreview(initialScene: scene)
                }
                .frame(minWidth: 600, minHeight: 400)
            }
        }
    }

    private var inspectorSidebar: some View {
        LocationsInspectorView(
            viewModel: viewModel,
            locations: locations,
            selectedLocation: $selectedLocation,
            onLocationSelected: { location in
                selectLocation(location)
            }
        )
    }
    #endif

    #if os(iOS)
    private var iOSLayout: some View {
        mapView
            .toolbar {
                if selectedLocation != nil, lookAroundScene != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            sheetDetent = .fraction(0.25)
                            showLookAround = true
                        } label: {
                            Image(systemName: "binoculars.fill")
                        }
                    }
                }
            }
            .lookAroundViewer(isPresented: $showLookAround, scene: $lookAroundScene)
            .sheet(isPresented: $showLocationsList) {
                NavigationStack {
                    LocationsListSheet(
                        viewModel: viewModel,
                        locations: locations,
                        selectedLocation: $selectedLocation,
                        onLocationSelected: { location in
                            selectLocation(location)
                        },
                        onEnterStreetview: {
                            sheetDetent = .fraction(0.25)
                        }
                    )
                }
                .presentationDetents([.medium, .large, .fraction(0.25)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
            }
    }
    #endif

    // MARK: - Shared map view

    private var mapView: some View {
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
    }

    private func selectLocation(_ location: ManuscriptLocation) {
        selectedLocation = location
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
        print("🗺️ WorldMap: Fetching Look Around for: \(location.name) at \(coordinate.latitude), \(coordinate.longitude)")
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            do {
                let scene = try await request.scene
                print("🗺️ WorldMap: Look Around scene found: \(scene != nil)")
                await MainActor.run {
                    lookAroundScene = scene
                }
            } catch {
                print("🗺️ WorldMap: Look Around error: \(error)")
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
    var onEnterStreetview: (() -> Void)?

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
                    LocationDetailView(
                        viewModel: viewModel,
                        location: location,
                        onEnterStreetview: onEnterStreetview
                    )
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
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
    }
}

// MARK: - macOS Inspector Sidebar

#if os(macOS)
struct LocationsInspectorView: View {
    @ObservedObject var viewModel: DocumentViewModel
    let locations: [ManuscriptLocation]
    @Binding var selectedLocation: ManuscriptLocation?
    let onLocationSelected: (ManuscriptLocation) -> Void
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    ForEach(locations) { location in
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(selectedLocation?.id == location.id
                                    ? .blue
                                    : Color(red: 0.6, green: 0.4, blue: 0.2))
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.name)
                                    .font(.headline)

                                Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                navigationPath.append(location.id)
                            } label: {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 12)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onLocationSelected(location)
                        }
                        .background(selectedLocation?.id == location.id ? Color.accentColor.opacity(0.2) : Color.clear)
                        .cornerRadius(6)
                    }
                } header: {
                    Text("Locations")
                }
            }
            .listStyle(.sidebar)
            .navigationDestination(for: UUID.self) { locationId in
                if let location = locations.first(where: { $0.id == locationId }) {
                    LocationDetailView(viewModel: viewModel, location: location)
                }
            }
        }
    }
}
#endif

#if DEBUG
#Preview {
    // Preview requires a DocumentViewModel, so we can't easily preview this
    Text("WorldMapSheet Preview - requires DocumentViewModel")
}
#endif
