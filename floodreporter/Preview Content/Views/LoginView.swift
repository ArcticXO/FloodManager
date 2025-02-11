import SwiftUI
import Combine

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @AppStorage("loggedInUsername") var loggedInUsername: String = ""
    @AppStorage("loggedInPassword") var loggedInPassword: String = "" // INSECURE - FOR DEMO ONLY

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: {
                    login()
                }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                NavigationLink("Don't have an account? Register", destination: RegisterView(isLoggedIn: $isLoggedIn))
                    .foregroundColor(.blue)
            }
            .padding()
            .navigationTitle("Login")
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func login() {
        let sanitizedUsername = username.lowercased()

        guard !sanitizedUsername.isEmpty, !password.isEmpty else {
            alertMessage = "Username and password are required."
            showingAlert = true
            return
        }

        AuthService.shared.login(username: sanitizedUsername, password: password)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }, receiveValue: { success in
                if success {
                    isLoggedIn = true
                    loggedInUsername = sanitizedUsername
                    loggedInPassword = password // INSECURE - FOR DEMO ONLY
                } else {
                    alertMessage = "Invalid username or password."
                    showingAlert = true
                }
            })
            .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}
