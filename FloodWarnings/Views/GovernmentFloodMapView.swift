import SwiftUI
import MapKit

struct GovernmentFloodMapView: UIViewRepresentable {
    @Binding var floodWarnings: [FloodWarning]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Remove existing overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        // Add new overlays and annotations for each flood warning
        for warning in floodWarnings {
            // Add circle overlay
            let circle = MKCircle(
                center: warning.coordinate, // Use the centroid coordinate
                radius: warning.centroid.radius * 1000 // Convert radius to meters
            )
            mapView.addOverlay(circle)

            // Add annotation for the flood warning description
            let annotation = MKPointAnnotation()
            annotation.coordinate = warning.coordinate // Use the centroid coordinate
            annotation.title = warning.description
            mapView.addAnnotation(annotation)
        }

        // Set the map region to show all flood warnings
        if let firstWarning = floodWarnings.first {
            let region = MKCoordinateRegion(
                center: firstWarning.coordinate, // Use the centroid coordinate
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0) // Adjust span as needed
            )
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GovernmentFloodMapView

        init(_ parent: GovernmentFloodMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor.blue.withAlphaComponent(0.3) // Semi-transparent blue
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let identifier = "FloodWarningAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            return annotationView
        }
    }
}
