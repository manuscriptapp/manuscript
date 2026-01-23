import SwiftUI
import MapKit

struct LocationDetailView: View {
    @ObservedObject var viewModel: DocumentViewModel
    let location: ManuscriptLocation
    var onEnterStreetview: (() -> Void)?
    @State private var editedName: String
    @State private var editedLatitude: Double
    @State private var editedLongitude: Double
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showLookAround = false
    @State private var mapCameraPosition: MapCameraPosition

    init(viewModel: DocumentViewModel, location: ManuscriptLocation, onEnterStreetview: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.location = location
        self.onEnterStreetview = onEnterStreetview
        self._editedName = State(initialValue: location.name)
        self._editedLatitude = State(initialValue: location.latitude)
        self._editedLongitude = State(initialValue: location.longitude)
        self._mapCameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        Form {
            // Map section with Look Around button
            Section {
                ZStack {
                    Map(position: $mapCameraPosition) {
                        Marker(location.name, coordinate: CLLocationCoordinate2D(
                            latitude: editedLatitude,
                            longitude: editedLongitude
                        ))
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Look Around button overlay (iOS only)
                    #if os(iOS)
                    if lookAroundScene != nil {
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    onEnterStreetview?()
                                    showLookAround = true
                                } label: {
                                    Image(systemName: "binoculars.fill")
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                        )
                                }
                                .padding(8)
                            }
                            Spacer()
                        }
                    }
                    #endif
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } header: {
                HStack {
                    Text("Map")
                    Spacer()
                    if lookAroundScene == nil {
                        Text("Look Around unavailable")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                TextField("Name", text: $editedName)
                    .onChange(of: editedName) { _, _ in updateLocation() }

                HStack {
                    Text("Latitude")
                    Spacer()
                    TextField("Latitude", value: $editedLatitude, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editedLatitude) { _, _ in updateLocation() }
                }

                HStack {
                    Text("Longitude")
                    Spacer()
                    TextField("Longitude", value: $editedLongitude, format: .number)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editedLongitude) { _, _ in updateLocation() }
                }
            } header: {
                Text("Location Details")
            }

            Section {
                if location.appearsInDocumentIds.isEmpty {
                    Text("This location doesn't appear in any documents yet.")
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    ForEach(location.appearsInDocumentIds, id: \.self) { docId in
                        if let doc = viewModel.findDocument(withId: docId) {
                            HStack {
                                Image(systemName: doc.iconName)
                                    .foregroundStyle(Color(doc.colorName.lowercased()))
                                Text(doc.title)
                            }
                        }
                    }
                }
            } header: {
                Text("Appears in Documents")
            }
        }
        .navigationTitle(location.name)
        #if os(iOS)
        .lookAroundViewer(isPresented: $showLookAround, scene: $lookAroundScene)
        #endif
        .onAppear {
            fetchLookAroundScene()
        }
        .onChange(of: editedLatitude) { _, _ in
            updateMapPosition()
            fetchLookAroundScene()
        }
        .onChange(of: editedLongitude) { _, _ in
            updateMapPosition()
            fetchLookAroundScene()
        }
    }

    private func updateLocation() {
        viewModel.updateLocation(
            location,
            name: editedName,
            latitude: editedLatitude,
            longitude: editedLongitude
        )
    }

    private func updateMapPosition() {
        mapCameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: editedLatitude, longitude: editedLongitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    private func fetchLookAroundScene() {
        let coordinate = CLLocationCoordinate2D(latitude: editedLatitude, longitude: editedLongitude)
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            do {
                let scene = try await request.scene
                await MainActor.run {
                    lookAroundScene = scene
                }
            } catch {
                await MainActor.run {
                    lookAroundScene = nil
                }
            }
        }
    }
}

