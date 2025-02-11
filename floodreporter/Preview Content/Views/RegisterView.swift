import SwiftUI
import Combine

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var postcode: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            TextField("First Name", text: $firstName)
            TextField("Last Name", text: $lastName)
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            SecureField("Password", text: $password)
            TextField("Postcode", text: $postcode)
        }
        .navigationTitle("Register")
        .toolbar {
            Button("Submit") {
                register()
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Message"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func register() {
        // Sanitize username: Convert to lowercase
        let sanitizedUsername = username.lowercased()

        AuthService.shared.register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            username: sanitizedUsername, // Use sanitized username
            password: password,
            postcode: postcode
        )
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
                alertMessage = "Registration successful! Please log in."
                showingAlert = true
                isLoggedIn = true // Automatically log in after registration
            } else {
                alertMessage = "Registration failed"
                showingAlert = true
            }
        })
        .store(in: &cancellables)
    }

    @State private var cancellables = Set<AnyCancellable>()
}
