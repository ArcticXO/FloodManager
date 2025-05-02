import CoreLocation
import Combine
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false
    @Published var shouldCenterOnUser = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        print("LocationManager initialized")
    }
    
    func requestLocation() {
        isLoading = true
        print("Requesting location with authorization status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
        case .notDetermined:
            print("Requesting when-in-use authorization")
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            print("Requesting location update")
            manager.requestLocation()
        default:
            isLoading = false
            print("Location services not authorized")
        }
    }
    
    func centerMapOnUser(mapView: MKMapView) {
        guard let userLocation = userLocation else {
            print("No user location available to center on")
            return
        }
        print("Centering map on user location: \(userLocation)")
        let region = MKCoordinateRegion(center: userLocation, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
        shouldCenterOnUser = false
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            print("Received new location: \(location.coordinate)")
            self.userLocation = location.coordinate
            self.isLoading = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
        isLoading = false
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("Authorization status changed from \(authorizationStatus.rawValue) to \(newStatus.rawValue)")
        authorizationStatus = newStatus
        
        if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            print("Authorization granted - requesting location")
            manager.requestLocation()
        }
    }
}
