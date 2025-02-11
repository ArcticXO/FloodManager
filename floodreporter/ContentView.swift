import SwiftUI

struct ContentView: View {
    @State private var isLoggedIn: Bool = false // Use @State to track login state

    var body: some View {
        if isLoggedIn {
            MainTabView(isLoggedIn: $isLoggedIn) // Pass the binding to MainTabView
        } else {
            LoginView(isLoggedIn: $isLoggedIn) // Pass the binding to LoginView
        }
    }
}
