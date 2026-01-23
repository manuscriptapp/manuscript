import SwiftUI
import MapKit

struct LocationDetailView: View {
    @ObservedObject var viewModel: DocumentViewModel
    let location: ManuscriptLocation
    @State private var editedName: String
    @State private var editedLatitude: Double
    @State private var editedLongitude: Double
    @State private var showLookAround: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var mapCameraPosition: MapCameraPosition

    init(viewModel: DocumentViewModel, location: ManuscriptLocation) {
        self.viewModel = viewModel
        self.location = location
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
            // Map/Look Around section
            Section {
                ZStack {
                    if showLookAround, let scene = lookAroundScene {
                        LookAroundPreview(scene: .constant(scene))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Map(position: $mapCameraPosition) {
                            Marker(location.name, coordinate: CLLocationCoordinate2D(
                                latitude: editedLatitude,
                                longitude: editedLongitude
                            ))
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // Toggle button overlay
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                showLookAround.toggle()
                            } label: {
                                Image(systemName: showLookAround ? "map.fill" : "binoculars.fill")
                                    .font(.body)
                                    .foregroundStyle(.white)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(lookAroundScene != nil ? Color.black.opacity(0.6) : Color.gray.opacity(0.6))
                                    )
                            }
                            .disabled(lookAroundScene == nil && !showLookAround)
                            .padding(8)
                        }
                        Spacer()
                    }
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
                    showLookAround = false
                }
            }
        }
    }
}

