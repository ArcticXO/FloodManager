import SwiftUI

struct FloodDetailView: View {
    let flood: Flood

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(flood.title)       // Display title
                .font(.title)
                .bold()
                .padding(.bottom, 10)

            // ... other details

            Text("Description: \(flood.description)") // Display description
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
