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
        #if os(macOS)
        ScrollView {
            formContent
                .frame(maxWidth: 600)
                .padding()
        }
        .frame(maxWidth: .infinity)
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
        #else
        Form {
            formContent
        }
        .navigationTitle(location.name)
        .lookAroundViewer(isPresented: $showLookAround, scene: $lookAroundScene)
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
        #endif
    }

    @ViewBuilder
    private var formContent: some View {
        #if os(macOS)
        VStack(alignment: .leading, spacing: 20) {
            // Map section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Map")
                        .font(.headline)
                    Spacer()
                    if lookAroundScene != nil {
                        Button {
                            showLookAround = true
                        } label: {
                            Label("Look Around", systemImage: "binoculars.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Text("Look Around unavailable")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Map(position: $mapCameraPosition) {
                    Marker(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: editedLatitude,
                        longitude: editedLongitude
                    ))
                }
                .mapStyle(.standard(elevation: .realistic))
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Divider()

            // Location Details section
            VStack(alignment: .leading, spacing: 12) {
                Text("Location Details")
                    .font(.headline)

                LabeledContent("Name") {
                    TextField("Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 300)
                        .onChange(of: editedName) { _, _ in updateLocation() }
                }

                LabeledContent("Latitude") {
                    TextField("Latitude", value: $editedLatitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onChange(of: editedLatitude) { _, _ in updateLocation() }
                }

                LabeledContent("Longitude") {
                    TextField("Longitude", value: $editedLongitude, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onChange(of: editedLongitude) { _, _ in updateLocation() }
                }
            }

            Divider()

            // Appears in Documents section
            VStack(alignment: .leading, spacing: 8) {
                Text("Appears in Documents")
                    .font(.headline)

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
            }
        }
        #else
        Group {
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
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: editedLatitude) { _, _ in updateLocation() }
                }

                HStack {
                    Text("Longitude")
                    Spacer()
                    TextField("Longitude", value: $editedLongitude, format: .number)
                        .keyboardType(.decimalPad)
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
        #endif
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
        print("🔍 Fetching Look Around for: \(coordinate.latitude), \(coordinate.longitude)")
        Task {
            let request = MKLookAroundSceneRequest(coordinate: coordinate)
            do {
                let scene = try await request.scene
                print("✅ Look Around scene found: \(scene != nil)")
                await MainActor.run {
                    lookAroundScene = scene
                }
            } catch {
                print("❌ Look Around error: \(error)")
                await MainActor.run {
                    lookAroundScene = nil
                }
            }
        }
    }
}

