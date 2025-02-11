import Foundation
import Combine
import SwiftUI

class NetworkService {
    static let shared = NetworkService()
    private let baseURL = "http://192.168.156.60:4999" // REPLACE WITH YOUR ACTUAL BACKEND URL!!!

    func fetchFloods() -> AnyPublisher<[Flood], Error> {
        let url = URL(string: "\(baseURL)/view_floods")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Flood].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func reportFlood(severity: Int, radius: Double, longitude: Double, latitude: Double, title: String, description: String) -> AnyPublisher<Bool, Error> {
        let url = URL(string: "\(baseURL)/report_flood")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let loggedInUsername = UserDefaults.standard.string(forKey: "loggedInUsername")
        let loggedInPassword = UserDefaults.standard.string(forKey: "loggedInPassword")

        guard let username = loggedInUsername, let password = loggedInPassword, !username.isEmpty, !password.isEmpty else {
            return Fail(error: NSError(domain: "YourAppDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username or password not available"])).eraseToAnyPublisher()
        }

        let body: [String: Any] = [
            "severity": severity,
            "radius": radius,
            "gps_longitude": longitude,
            "gps_latitude": latitude,
            "username": username,
            "password": password,
            "title": title,
            "description": description
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: [String: String].self, decoder: JSONDecoder())
            .map { response in
                return response["message"] == "Flood reported successfully" || response["message"] == "Flood report added successfully" // Handle multiple success messages
            }
            .catch { error in
                Fail(error: error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
