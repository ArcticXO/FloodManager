import SwiftUI

@main
struct FloodWarningsApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var networkManager = NetworkManager.shared
    

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                TabbedView()
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
                    .environmentObject(LocationManager())

            } else {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
                    .environmentObject(LocationManager())

            }
        }
    }
}
