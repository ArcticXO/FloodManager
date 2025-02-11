import SwiftUI
import MapKit
import Combine
import CoreLocation

struct FloodMapView: View {
    @State private var floods: [Flood] = []
    @State private var region = EquatableCoordinateRegion(
        region: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.4808, longitude: -2.2426), // Default location (e.g., Manchester)
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    )
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var selectedFlood: Flood? = nil
    @State private var shouldAutoRecenter: Bool = false
    @State private var showAddFloodView: Bool = false
    @State private var selectedLocation: CLLocationCoordinate2D? = nil
    @State private var cancellables = Set<AnyCancellable>()
    @State private var timer: Timer?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(
                coordinateRegion: $region.region,
                showsUserLocation: true,
                annotationItems: floods
            ) { flood in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: flood.gpsLatitude, longitude: flood.gpsLongitude)) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(Text("\(flood.severity)").foregroundColor(.white))
                        .onTapGesture {
                            selectedFlood = flood
                        }
                }
            }
            .onChange(of: region) { _ in
                shouldAutoRecenter = false
            }
            .onTapGesture { location in
                let mapCoordinate = region.region.center // Get the center of the map
                selectedLocation = mapCoordinate
            }
            .edgesIgnoringSafeArea([.top, .leading, .trailing])
            .sheet(item: $selectedFlood) { flood in
                FloodDetailView(flood: flood)
            }

            VStack(spacing: 16) {
                Button(action: {
                    recenterMap()
                }) {
                    Image(systemName: "location.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }

                Button(action: {
                    showAddFloodView = true
                    selectedLocation = nil // Clear the selected location
                }) {
                    Image(systemName: "plus")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showAddFloodView) {
            // Pass either the tapped location or the user's current location
            if let location = selectedLocation {
                AddFloodView(isLoggedIn: $isLoggedIn, userLocation: CLLocation(latitude: location.latitude, longitude: location.longitude))
            } else if let userLocation = locationManager.userLocation {
                AddFloodView(isLoggedIn: $isLoggedIn, userLocation: userLocation)
            } else {
                AddFloodView(isLoggedIn: $isLoggedIn, userLocation: nil) // Handle no location
            }
        }
        .onAppear {
            if isLoggedIn {
                fetchFloods()
                startAutoRefresh()
                recenterMap()
            }
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .onChange(of: locationManager.userLocation) { newLocation in
            if shouldAutoRecenter, let newLocation = newLocation {
                region.region.center = CLLocationCoordinate2D(
                    latitude: newLocation.coordinate.latitude,
                    longitude: newLocation.coordinate.longitude
                )
            }
        }
    }

    private func fetchFloods() {
        NetworkService.shared.fetchFloods()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("Error fetching floods: \(error.localizedDescription)")
                }
            }, receiveValue: { newFloods in
                self.floods = newFloods
            })
            .store(in: &cancellables)
    }

    private func recenterMap() {
        if let userLocation = locationManager.userLocation {
            region.region.center = CLLocationCoordinate2D(
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude
            )
            shouldAutoRecenter = true
        }
    }

    private func startAutoRefresh() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            fetchFloods()
        }
    }

    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
}
