//
//  NetworkManager.swift
//  FloodWarnings
//
//  Created by Ali on 20/03/2025.
//

import Foundation

class NetworkManager: ObservableObject {
    // Singleton instance
    static let shared = NetworkManager()

    // Server address
    private let serverAddress: String

    private init() {
        // Set the server address (you can load this from UserDefaults or a config file)
        self.serverAddress = "http://192.168.1.140:4999"
    }

    // Generic function to make a POST request
    func postRequest<T: Decodable>(endpoint: String, parameters: [String: Any], responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: "\(serverAddress)\(endpoint)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    // Generic function to make a GET request with a 10-second timeout
    func getRequest<T: Decodable>(endpoint: String, responseType: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: "\(serverAddress)\(endpoint)") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        // Create a URLSessionConfiguration with a 10-second timeout
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 10.0 // 10 seconds
        sessionConfig.timeoutIntervalForResource = 10.0 // 10 seconds

        // Create a URLSession with the custom configuration
        let session = URLSession(configuration: sessionConfig)

        // Use the custom session for the data task
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
}

// Custom error for network-related issues
