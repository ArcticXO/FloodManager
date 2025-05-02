import SwiftUI

struct FloodListView: View {
    @Binding var floods: [Flood]

    var body: some View {
        List(floods) { flood in
            VStack(alignment: .leading) {
                Text(flood.title)
                    .font(.headline)
                Text("Lat: \(flood.gps_latitude), Lon: \(flood.gps_longitude)")
                    .font(.subheadline)
                Text("Severity: \(flood.severity)")
                    .font(.subheadline)
                Text("Reported by: \(flood.username)")
                    .font(.subheadline)
                Text("Time: \(flood.time_reported)")
                    .font(.subheadline)
            }
        }
    }
}
