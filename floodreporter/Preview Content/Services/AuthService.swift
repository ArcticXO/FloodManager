//
//  AuthService.swift
//  floodreporter
//
//  Created by Ali Al Abdullah on 31/01/2025.
//


import Foundation
import Combine

class AuthService {
    static let shared = AuthService()
    private let baseURL = "http://192.168.156.60:4999" // Replace with your backend URL

    // Register a new user
    func register(
        firstName: String,
        lastName: String,
        email: String,
        username: String,
        password: String,
        postcode: String
    ) -> AnyPublisher<Bool, Error> {
        let url = URL(string: "\(baseURL)/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include all required fields in the request body
        let body: [String: Any] = [
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "username": username,
            "password": password,
            "postcode": postcode
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .map { $0["message"] == "User registered successfully" }
            .eraseToAnyPublisher()
    }

    // Log in a user
    func login(username: String, password: String) -> AnyPublisher<Bool, Error> {
        let url = URL(string: "\(baseURL)/authenticate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Include username and password in the request body
        let body: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .map { $0["message"] == "Login successful" }
            .eraseToAnyPublisher()
    }
}
