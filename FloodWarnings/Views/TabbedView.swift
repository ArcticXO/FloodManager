import SwiftUI
import MapKit

struct TabbedView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var locationManager = LocationManager()
    @State private var floods: [Flood] = []
    @State private var floodWarnings: [FloodWarning] = []

    var body: some View {
        TabView {
            // Home (Map) Tab
            NavigationStack {
                FloodMapView(floods: $floods, locationManager: locationManager)
                    .edgesIgnoringSafeArea(.all)
                    .navigationTitle("Home")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            // Floods (List) Tab
            NavigationStack {
                FloodListView(floods: $floods)
                    .navigationTitle("Floods")
                    .onAppear{
                        fetchData()
                    }
            }
            .tabItem {
                Label("Floods", systemImage: "list.bullet")
            }

            // Add Flood Tab
            NavigationStack {
                AddFloodView(floods: $floods, locationManager: locationManager, authManager: _authManager)
                    .navigationTitle("Add Flood")
            }
            .tabItem {
                Label("Add Flood", systemImage: "plus.circle")
            }

            // Flood Warnings Tab
            NavigationStack {
                GovernmentFloodMapView(floodWarnings: $floodWarnings)
                    .environmentObject(locationManager)
                    .navigationTitle("Flood Warnings")
            }
            .tabItem {
                Label("Warnings", systemImage: "exclamationmark.triangle.fill")
            }

            // Profile Tab (Non-functional)

        }
        .onAppear {
            fetchData()
        }
        .edgesIgnoringSafeArea(.bottom)
    }

    private func fetchData() {
        NetworkManager.shared.getRequest(
            endpoint: "/view_floods",
            responseType: [Flood].self
        ) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let floods):
                        self.floods = floods
                    case .failure(let error):
                        print("Error fetching floods: \(error.localizedDescription)")
                }
            }
        }

        NetworkManager.shared.getRequest(
            endpoint: "/simplified_flood_areas",
            responseType: FloodWarningResponse.self
        ) { result in
            DispatchQueue.main.async {
                switch result {
                    case .success(let response):
                        self.floodWarnings = response.items
                    case .failure(let error):
                        print("Error fetching warnings: \(error.localizedDescription)")
                }
            }
        }
    }
}

// AddFloodView.swift (New View)
struct AddFloodView: View {
    @Binding var floods: [Flood]
    @ObservedObject var locationManager: LocationManager
    @EnvironmentObject var authManager: AuthManager

    @State private var newFlood = Flood(
        id: 0, user_id: 0,
        gps_latitude: 0, gps_longitude: 0,
        radius: 0, severity: 1,
        time_reported: "", title: "", description: "", username: ""
    )

    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                // Flood Details Section
                Section {
                    TextField("Flood Title", text: $newFlood.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 5) // Reduce vertical padding to make it smaller
                        .frame(height: 40) // Set a fixed height for the title field
                    
                    TextField("Flood Description", text: $newFlood.description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 5) // Add some padding but keep it compact
                } header: {
                    Text("Flood Details")
                        .font(.headline)
                        .padding(.top, 8)
                }

                // Location Section
                Section {
                    if locationManager.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        if let userLocation = locationManager.userLocation {
                            Text("Current Location")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("You can only report floods at your current location.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Location not available")
                                .foregroundColor(.red)
                            Button("Request Location") {
                                locationManager.requestLocation()
                            }
                            .padding(.top, 4)
                        }
                    }
                } header: {
                    Text("Location")
                        .font(.headline)
                        .padding(.top, 8)
                }

                // Severity Section
                Section {
                    VStack(alignment: .leading) {
                        Slider(
                            value: Binding(
                                get: { Double(newFlood.severity) },
                                set: { newFlood.severity = Int($0) }
                            ),
                            in: 1...5,
                            step: 1
                        )
                        .padding(.bottom, 8)
                        
                        Text("Severity: \(newFlood.severity)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Severity")
                        .font(.headline)
                        .padding(.top, 8)
                }

                // Submit Section
                Section {
                    Button(action: submitFlood) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Flood")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.vertical, 8)
                    .disabled(isLoading || locationManager.userLocation == nil)
                }
            }
            .navigationTitle("Report Flood")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Report Status", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                locationManager.requestLocation()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func submitFlood() {
        guard authManager.isAuthenticated else {
            alertMessage = "You must be logged in to report a flood."
            showAlert = true
            return
        }

        guard !newFlood.title.isEmpty else {
            alertMessage = "Title is required"
            showAlert = true
            return
        }

        guard let userLocation = locationManager.userLocation else {
            alertMessage = "Please enable location services to report a flood"
            showAlert = true
            return
        }

        isLoading = true

        // Fetch username and password from UserDefaults
        let storedUsername = UserDefaults.standard.string(forKey: "username") ?? ""
        let storedPassword = UserDefaults.standard.string(forKey: "password") ?? ""

        // Check if username and password are present
        guard !storedUsername.isEmpty, !storedPassword.isEmpty else {
            alertMessage = "You must be logged in to report a flood."
            showAlert = true
            isLoading = false
            return
        }

        let parameters: [String: Any] = [
            "username": storedUsername,
            "password": storedPassword,
            "gps_longitude": userLocation.longitude,
            "gps_latitude": userLocation.latitude,
            "radius": 100,
            "severity": newFlood.severity,
            "title": newFlood.title,
            "description": newFlood.description
        ]

        NetworkManager.shared.postRequest(
            endpoint: "/report_flood",
            parameters: parameters,
            responseType: [String: String].self
        ) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let response):
                    if response["message"] != nil {
                        alertMessage = "Flood reported successfully"
                        newFlood = Flood(
                            id: 0, user_id: 0,
                            gps_latitude: 0, gps_longitude: 0,
                            radius: 0, severity: 1,
                            time_reported: "", title: "", description: "", username: ""
                        )
                    } else {
                        alertMessage = response["error"] ?? "Unknown error"
                    }

                case .failure(let error):
                    alertMessage = error.localizedDescription
                }

                showAlert = true
            }
        }
    }
}
