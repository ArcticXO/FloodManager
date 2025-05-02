import SwiftUI
import MapKit

struct FloodMapView: View {
    @Binding var floods: [Flood]
    @ObservedObject var locationManager: LocationManager
    @State private var mapView = MKMapView()
    @State private var showPermissionAlert = false
    @State private var showAddFloodView = false  // Control showing the Add Flood view
    
    var body: some View {
        ZStack {
            // Main Map View
            MapViewWrapper(
                floods: $floods,
                locationManager: locationManager,
                mapView: $mapView
            )
            .edgesIgnoringSafeArea(.all)
            
            // Right side VStack for buttons, centered vertically
            VStack {
                // Recenter Button
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 3)
                }
                .disabled(!locationManager.isLocationAuthorized)
                .opacity(locationManager.isLocationAuthorized ? 1 : 0.5)
                .padding(.trailing, 20)
                .padding(.bottom, 8)  // Reduced spacing between buttons
                
                // Plus Button to add a flood
                Button(action: { showAddFloodView.toggle() }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.blue))
                        .shadow(radius: 3)
                }
                .padding(.trailing, 20)
                .sheet(isPresented: $showAddFloodView) {
                    // Present the AddFloodView when the button is pressed
                    AddFloodView(floods: $floods, locationManager: locationManager)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing) // Aligns the VStack to the right
            .offset(y: 0) // Center vertically (0 offset from center)
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Location Permission Required"),
                message: Text("Please enable location services in Settings to use this feature."),
                primaryButton: .default(Text("Settings"), action: openAppSettings),
                secondaryButton: .cancel()
            )
        }
        .onChange(of: locationManager.authorizationStatus) { status in
            showPermissionAlert = (status == .denied || status == .restricted)
        }
    }
    
    private func centerOnUserLocation() {
        locationManager.centerMapOnUser(mapView: mapView)
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

extension LocationManager {
    var isLocationAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }
}

struct MapViewWrapper: UIViewRepresentable {
    @Binding var floods: [Flood]
    var locationManager: LocationManager
    @Binding var mapView: MKMapView
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        updateFloodDisplay(mapView: mapView)
        
        if locationManager.userLocation == nil && !floods.isEmpty {
            centerOnFirstFlood(mapView: mapView)
        }
    }
    
    private func updateFloodDisplay(mapView: MKMapView) {
        let floodOverlays = mapView.overlays.filter { $0 is MKCircle }
        mapView.removeOverlays(floodOverlays)
        
        let floodAnnotations = mapView.annotations.filter { $0 is MKPointAnnotation }
        mapView.removeAnnotations(floodAnnotations)
        
        for flood in floods {
            let circle = MKCircle(
                center: CLLocationCoordinate2D(
                    latitude: flood.gps_latitude,
                    longitude: flood.gps_longitude
                ),
                radius: flood.radius
            )
            mapView.addOverlay(circle)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: flood.gps_latitude,
                longitude: flood.gps_longitude
            )
            annotation.title = flood.title
            annotation.subtitle = flood.description
            mapView.addAnnotation(annotation)
        }
    }
    
    private func centerOnFirstFlood(mapView: MKMapView) {
        guard let firstFlood = floods.first else { return }
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: firstFlood.gps_latitude,
                longitude: firstFlood.gps_longitude
            ),
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        mapView.setRegion(region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewWrapper
        
        init(_ parent: MapViewWrapper) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.3)
                renderer.strokeColor = .systemRed
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !annotation.isKind(of: MKUserLocation.self) else { return nil }
            
            let identifier = "FloodAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                (annotationView as? MKMarkerAnnotationView)?.glyphImage = UIImage(systemName: "exclamationmark.triangle")
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .systemRed
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
    }
}
