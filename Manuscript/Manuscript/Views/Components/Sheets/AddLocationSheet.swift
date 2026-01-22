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
    @State private var coordinate = CLLocationCoordinate2D(latitude: 37.3346, longitude: -122.0090) // Default to Apple Park if location fails
    
    var body: some View {
        NavigationStack {
            Form(content: {
                TextField("Location Name", text: $name)
                
                Section("Location") {
                    switch locationManager.authorizationStatus {
                    case .notDetermined:
                        HStack {
                            Spacer()
                            Button("Allow Location Access") {
                                locationManager.requestLocationPermission()
                            }
                            Spacer()
                        }
                        .frame(height: 300)
                    case .restricted, .denied:
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Text("Location Access Required")
                                    .font(.headline)
                                Text("Please enable location access in Settings to use this feature.")
                                    .multilineTextAlignment(.center)
                            }
                            Spacer()
                        }
                        .frame(height: 300)
                    #if os(iOS)
                    case .authorizedWhenInUse:
                        locationContent
                    case .authorizedAlways:
                        locationContent
                    #else
                    case .authorizedAlways:
                        locationContent
                    #endif
                    @unknown default:
                        EmptyView()
                    }
                }
            })
            .navigationTitle("Add Location")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationBackground(.regularMaterial)
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                ))
                coordinate = location.coordinate
            }
        }
    }
    
    @ViewBuilder
    private var locationContent: some View {
        if locationManager.isLoading {
            HStack {
                Spacer()
                ProgressView("Getting your location...")
                Spacer()
            }
            .frame(height: 300)
        } else {
            Map(position: $position) {
                Annotation("Selected Location", coordinate: coordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
            }
            .frame(height: 300)
            .onMapCameraChange { context in
                coordinate = context.region.center
            }
            
            LabeledContent("Latitude") {
                Text(String(format: "%.6f", coordinate.latitude))
            }
            LabeledContent("Longitude") {
                Text(String(format: "%.6f", coordinate.longitude))
            }
        }
    }
}

