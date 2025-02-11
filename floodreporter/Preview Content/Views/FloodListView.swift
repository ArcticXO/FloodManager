import SwiftUI
import Combine

struct FloodListView: View {
    @State private var floods: [Flood] = []
    @Binding var isLoggedIn: Bool

    var body: some View {
        NavigationView { // Add NavigationView
            List { // Add List here
                ForEach(floods) { flood in // Use ForEach to iterate over floods
                    NavigationLink(destination: FloodDetailView(flood: flood)) { // Add NavigationLink
                        VStack(alignment: .leading) {
                            Text(flood.title) // Display title
                                .font(.headline)
                            Text("Reported by: \(flood.username)")
                            Text("Severity: \(flood.severity)")
                            Text("Location: \(flood.gpsLatitude), \(flood.gpsLongitude)")
                            Text("Time: \(flood.timeReported)")
                        }
                    }
                }
            }
            .navigationTitle("Floods") // Set the navigation title
            .onAppear {
                if isLoggedIn {
                    fetchFloods()
                }
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
                print("Fetched floods: \(newFloods)")
                self.floods = newFloods
            })
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}
