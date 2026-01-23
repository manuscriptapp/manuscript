import SwiftUI

struct LocationDetailView: View {
    @ObservedObject var viewModel: DocumentViewModel
    let location: ManuscriptLocation
    @State private var editedName: String
    @State private var editedLatitude: Double
    @State private var editedLongitude: Double

    init(viewModel: DocumentViewModel, location: ManuscriptLocation) {
        self.viewModel = viewModel
        self.location = location
        self._editedName = State(initialValue: location.name)
        self._editedLatitude = State(initialValue: location.latitude)
        self._editedLongitude = State(initialValue: location.longitude)
    }

    var body: some View {
        Form {
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
    }

    private func updateLocation() {
        viewModel.updateLocation(
            location,
            name: editedName,
            latitude: editedLatitude,
            longitude: editedLongitude
        )
    }
}

