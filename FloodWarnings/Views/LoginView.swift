import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isRegistering: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(isRegistering ? "Register" : "Login")
                .font(.largeTitle)
                .bold()

            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Toggle("Remember Me", isOn: $rememberMe)
                .toggleStyle(SwitchToggleStyle(tint: .blue))

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Button(action: isRegistering ? register : login) {
                Text(isRegistering ? "Register" : "Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: { isRegistering.toggle() }) {
                Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            // Load saved credentials if "Remember Me" was checked
            if let savedUsername = UserDefaults.standard.string(forKey: "username"),
               let savedPassword = UserDefaults.standard.string(forKey: "password") {
                username = savedUsername
                password = savedPassword
                rememberMe = true
            }
        }
    }

    private func login() {
        let parameters: [String: Any] = ["username": username, "password": password]
        NetworkManager.shared.postRequest(endpoint: "/authenticate", parameters: parameters, responseType: LoginResponse.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let loginResponse):
                    if loginResponse.message == "Login successful" {
                        if rememberMe {
                            UserDefaults.standard.set(username, forKey: "username")
                            UserDefaults.standard.set(password, forKey: "password")
                        }
                        authManager.login() // Update authentication state
                    } else {
                        errorMessage = "Invalid credentials"
                    }
                case .failure(let error):
                    errorMessage = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func register() {
        let parameters: [String: Any] = ["username": username, "password": password]
        NetworkManager.shared.postRequest(endpoint: "/register", parameters: parameters, responseType: RegisterResponse.self) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let registerResponse):
                    if registerResponse.message == "User registered successfully" {
                        isRegistering = false
                        errorMessage = "Registration successful. Please login."
                    } else {
                        errorMessage = registerResponse.error ?? "Registration failed"
                    }
                case .failure(let error):
                    errorMessage = "Registration failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
