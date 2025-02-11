import SwiftUI

struct MainTabView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        TabView {
            FloodMapView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            FloodListView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
        }
        .background(Color(.systemBackground)) // Ensure the navbar has a solid background
    }
}
