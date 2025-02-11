import SwiftUI
import Combine
import CoreLocation

struct AddFloodView: View {
    @Binding var isLoggedIn: Bool
    @State private var severity: String = ""
    @State private var radius: String = ""
    @State private var title: String = ""       // Add title state
    @State private var description: String = ""  // Add description state
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    let userLocation: CLLocation?

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)          // Add title text field
                TextField("Description", text: $description) // Add description text field
                TextField("Severity (1-5)", text: $severity)
                    .keyboardType(.numberPad)
                TextField("Radius (meters)", text: $radius)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Report Flood")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        reportFlood()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func reportFlood() {
        guard let severityInt = Int(severity), (1...5).contains(severityInt),
              let radiusDouble = Double(radius), radiusDouble > 0,
              !title.isEmpty, !description.isEmpty else { // Check for title and description
            alertMessage = "Please enter valid title, description, severity (1-5) and radius (positive number)."
            showingAlert = true
            return
        }

        guard let userLocation = userLocation else {
            alertMessage = "Location not available. Please enable location services."
            showingAlert = true
            return
        }

        let locationCoordinates = userLocation.coordinate

        NetworkService.shared.reportFlood(severity: severityInt, radius: radiusDouble, longitude: locationCoordinates.longitude, latitude: locationCoordinates.latitude, title: title, description: description) // Pass title and description
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }, receiveValue: { success in
                if success {
                    alertMessage = "Flood reported successfully!"
                    showingAlert = true
                    presentationMode.wrappedValue.dismiss()
                } else {
                    alertMessage = "Failed to report flood."
                    showingAlert = true
                }
            })
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}
