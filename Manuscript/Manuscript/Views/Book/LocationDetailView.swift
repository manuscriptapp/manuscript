import SwiftUI
import MapKit
import SwiftData

struct LocationDetailView: View {
    let location: Location
    let book: Book
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMapStyle = 0
    @State private var cameraPosition: MapCameraPosition
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isLookAroundPresented = false
    @State private var isEditing = false
    @State private var editedName: String
    @State private var editedLatitude: Double
    @State private var editedLongitude: Double
    
    private let mapStyles = [
        ("Standard", MapStyle.standard),
        ("Hybrid", MapStyle.hybrid),
        ("Satellite", MapStyle.imagery)
    ]
    
    init(location: Location, book: Book) {
        self.location = location
        self.book = book
        _editedName = State(initialValue: location.name)
        _editedLatitude = State(initialValue: location.latitude)
        _editedLongitude = State(initialValue: location.longitude)
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )))
    }
    
    var body: some View {
        FormContainerView {
            VStack(alignment: .leading, spacing: 16) {
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name:")
                            .font(.subheadline)
                        TextField("Name", text: $editedName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latitude:")
                            .font(.subheadline)
                        TextField("Latitude", value: $editedLatitude, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Longitude:")
                            .font(.subheadline)
                        TextField("Longitude", value: $editedLongitude, format: .number)
                            .textFieldStyle(.roundedBorder)
                    }
                } else {
                    Text("Location: \(location.name)")
                        .font(.title)
                    Text("From: \(book.title)")
                        .font(.headline)
                }
                
                Picker("Map Style", selection: $selectedMapStyle) {
                    ForEach(0..<mapStyles.count, id: \.self) { index in
                        Text(mapStyles[index].0).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical)
                
                Map(position: $cameraPosition) {
                    Marker(location.name, coordinate: CLLocationCoordinate2D(
                        latitude: isEditing ? editedLatitude : location.latitude,
                        longitude: isEditing ? editedLongitude : location.longitude
                    ))
                }
                .mapStyle(mapStyles[selectedMapStyle].1)
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .task {
                    await loadLookAroundScene()
                }
                
                if lookAroundScene != nil {
                    VStack {
                        Button("Show Street View") {
                            isLookAroundPresented = true
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(location.name)
                    .font(.headline)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelEditing()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(isEditing)
        .sheet(isPresented: $isLookAroundPresented) {
            if let scene = lookAroundScene {
                NavigationStack {
                    LookAroundPreview(initialScene: scene)
                        .navigationTitle("Street View")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .ignoresSafeArea(edges: .bottom)
                }
            }
        }
    }
    
    private func loadLookAroundScene() async {
        let coordinate = CLLocationCoordinate2D(
            latitude: location.latitude,
            longitude: location.longitude
        )
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        lookAroundScene = try? await request.scene
    }
    
    private func saveChanges() {
        location.name = editedName
        location.latitude = editedLatitude
        location.longitude = editedLongitude
        try? modelContext.save()
        isEditing = false
    }
    
    private func cancelEditing() {
        editedName = location.name
        editedLatitude = location.latitude
        editedLongitude = location.longitude
        isEditing = false
    }
}

#if DEBUG
#Preview {
    let sampleLocation = Location(name: "Central Park", latitude: 40.7829, longitude: -73.9654)
    let sampleBook = PreviewData.flatBook
    
    return NavigationStack {
        LocationDetailView(location: sampleLocation, book: sampleBook)
    }
}
#endif
