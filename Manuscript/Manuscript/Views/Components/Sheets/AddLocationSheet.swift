import SwiftUI
import MapKit
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var isLoading = true
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse else { return }
        #else
        guard authorizationStatus == .authorizedAlways else { return }
        #endif
        isLoading = true
        locationManager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        #if os(iOS)
        if authorizationStatus == .authorizedWhenInUse {
            requestLocation()
        } else {
            isLoading = false
        }
        #else
        if authorizationStatus == .authorizedAlways {
            requestLocation()
        } else {
            isLoading = false
        }
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.location = location
        isLoading = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
    }
}

struct AddLocationSheet: View {
    @ObservedObject var viewModel: DocumentViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var name = ""
    @State private var position: MapCameraPosition = .automatic
    @State private var coordinate = CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090)
    @State private var latitudeText = "37.334600"
    @State private var longitudeText = "-122.009000"
    @State private var currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, latitude, longitude, search
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen map
                mapContent
                    .ignoresSafeArea(edges: .bottom)

                // Center pin indicator
                VStack {
                    Spacer()
                    Image(systemName: "mappin")
                        .font(.system(size: 40))
                        .foregroundStyle(.red)
                        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                    Spacer()
                }
                .allowsHitTesting(false)

                // Map controls overlay
                VStack {
                    HStack {
                        Spacer()
                        mapControls
                    }
                    .padding(.top, 8)
                    .padding(.trailing, 16)

                    Spacer()
                    inputPanel
                }

                // Search overlay
                if isSearching {
                    searchOverlay
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentSpan
                ))
                coordinate = location.coordinate
                updateTextFields()
            }
        }
    }

    // MARK: - Map Controls

    private var mapControls: some View {
        VStack(spacing: 8) {
            // Search button
            Button {
                withAnimation {
                    isSearching = true
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            // Zoom controls
            VStack(spacing: 0) {
                Button {
                    zoomIn()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(width: 30)

                Button {
                    zoomOut()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))

            // Current location button
            Button {
                goToCurrentLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Search Overlay

    private var searchOverlay: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search places...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .search)
                    .onSubmit {
                        performSearch()
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Button("Cancel") {
                    withAnimation {
                        isSearching = false
                        searchText = ""
                        searchResults = []
                    }
                }
            }
            .padding()
            .background(.regularMaterial)

            // Search results
            if !searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(searchResults, id: \.self) { item in
                            Button {
                                selectSearchResult(item)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "Unknown")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    if let address = item.placemark.title {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading)
                        }
                    }
                }
                .frame(maxHeight: 300)
                .background(.regularMaterial)
            }

            Spacer()
        }
        .onAppear {
            focusedField = .search
        }
    }

    @ViewBuilder
    private var mapContent: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            ZStack {
                Map(position: $position)
                    .onMapCameraChange { context in
                        coordinate = context.region.center
                        currentSpan = context.region.span
                        updateTextFields()
                    }

                VStack {
                    Spacer()
                    Button("Allow Location Access") {
                        locationManager.requestLocationPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 200)
                }
            }
        case .restricted, .denied:
            Map(position: $position)
                .onMapCameraChange { context in
                    coordinate = context.region.center
                    currentSpan = context.region.span
                    updateTextFields()
                }
        #if os(iOS)
        case .authorizedWhenInUse, .authorizedAlways:
            authorizedMapContent
        #else
        case .authorizedAlways:
            authorizedMapContent
        #endif
        @unknown default:
            Map(position: $position)
                .onMapCameraChange { context in
                    coordinate = context.region.center
                    currentSpan = context.region.span
                    updateTextFields()
                }
        }
    }

    @ViewBuilder
    private var authorizedMapContent: some View {
        if locationManager.isLoading {
            ZStack {
                Map(position: $position)
                ProgressView("Getting your location...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        } else {
            Map(position: $position)
                .onMapCameraChange { context in
                    coordinate = context.region.center
                    currentSpan = context.region.span
                    updateTextFields()
                }
        }
    }

    private var inputPanel: some View {
        VStack(spacing: 12) {
            // Name field
            TextField("Location Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .name)

            // Coordinates row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latitude")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Latitude", text: $latitudeText)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .latitude)
                        .onChange(of: latitudeText) { _, newValue in
                            updateCoordinateFromText()
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Longitude")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Longitude", text: $longitudeText)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .focused($focusedField, equals: .longitude)
                        .onChange(of: longitudeText) { _, newValue in
                            updateCoordinateFromText()
                        }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    // MARK: - Helper Functions

    private func updateTextFields() {
        latitudeText = String(format: "%.6f", coordinate.latitude)
        longitudeText = String(format: "%.6f", coordinate.longitude)
    }

    private func updateCoordinateFromText() {
        guard let lat = Double(latitudeText),
              let lon = Double(longitudeText),
              lat >= -90, lat <= 90,
              lon >= -180, lon <= 180 else { return }

        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        position = .region(MKCoordinateRegion(
            center: coordinate,
            span: currentSpan
        ))
    }

    private func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentSpan.latitudeDelta / 2, 0.001),
            longitudeDelta: max(currentSpan.longitudeDelta / 2, 0.001)
        )
        currentSpan = newSpan
        withAnimation {
            position = .region(MKCoordinateRegion(center: coordinate, span: newSpan))
        }
    }

    private func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentSpan.latitudeDelta * 2, 180),
            longitudeDelta: min(currentSpan.longitudeDelta * 2, 360)
        )
        currentSpan = newSpan
        withAnimation {
            position = .region(MKCoordinateRegion(center: coordinate, span: newSpan))
        }
    }

    private func goToCurrentLocation() {
        if let location = locationManager.location {
            currentSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: currentSpan
                ))
            }
            coordinate = location.coordinate
            updateTextFields()
        } else {
            locationManager.requestLocation()
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(center: coordinate, span: currentSpan)

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
            }
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let newCoordinate = item.placemark.coordinate
        coordinate = newCoordinate
        currentSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

        withAnimation {
            position = .region(MKCoordinateRegion(center: newCoordinate, span: currentSpan))
            isSearching = false
        }

        // Auto-fill name if empty
        if name.isEmpty, let placeName = item.name {
            name = placeName
        }

        searchText = ""
        searchResults = []
        updateTextFields()
    }
}
