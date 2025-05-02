import Foundation
import CoreLocation

// MARK: - Flood Model (for /view_floods endpoint)
struct Flood: Decodable, Identifiable {
    var id: Int  // Changed to var to allow mutation
    var user_id: Int  // Changed to var to allow mutation
    var gps_latitude: Double  // Changed to var to allow mutation
    var gps_longitude: Double  // Changed to var to allow mutation
    var radius: Double  // Changed to var to allow mutation
    var severity: Int  // Changed to var to allow mutation
    var time_reported: String
    var title: String  // Changed to var to allow mutation
    var description: String  // Changed to var to allow mutation
    var username: String

    // Map "flood_id" to "id" for Identifiable
    enum CodingKeys: String, CodingKey {
        case id = "flood_id"
        case user_id
        case gps_latitude
        case gps_longitude
        case radius
        case severity
        case time_reported
        case title
        case description
        case username
    }
}

// MARK: - FloodWarning Model (for /simplified_flood_areas endpoint)
struct FloodWarning: Decodable, Identifiable {
    // Generate a unique identifier since the JSON doesn't provide an `id`
    var id: String {
        return UUID().uuidString
    }

    var description: String  // Changed to var for mutation
    var centroid: Centroid  // Centroid remains a value type, so it’s fine

    // Optional fields (not present in the JSON response)
    var severity: String?
    var severityLevel: Int?

    enum CodingKeys: String, CodingKey {
        case description
        case centroid
        case severity
        case severityLevel
    }

    // Computed property to get the coordinate
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: centroid.latitude, longitude: centroid.longitude)
    }
}

// MARK: - Centroid Model (nested in FloodWarning)
struct Centroid: Decodable {
    var coordinates: [Double]  // Changed to var for mutation
    var radius: Double
    var type: String?  // Optional, as it might not be used in your app

    var latitude: Double {
        return coordinates[1]  // Latitude is the second value
    }

    var longitude: Double {
        return coordinates[0]  // Longitude is the first value
    }
}

// MARK: - FloodWarningResponse Model (wrapper for /simplified_flood_areas endpoint)
struct FloodWarningResponse: Decodable {
    let items: [FloodWarning]
}

// MARK: - PolygonResponse Model (for fetching polygon data)
struct PolygonResponse: Decodable {
    let coordinates: [[[Double]]]
}

// MARK: - NetworkError Enum
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
}

// MARK: - Helper Functions

/// Fetches polygon data from a URL and returns an array of coordinates.
func fetchPolygonData(url: String, completion: @escaping (Result<[CLLocationCoordinate2D], Error>) -> Void) {
    guard let polygonURL = URL(string: url) else {
        completion(.failure(NetworkError.invalidURL))
        return
    }

    URLSession.shared.dataTask(with: polygonURL) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(NetworkError.noData))
            return
        }

        do {
            let polygonResponse = try JSONDecoder().decode(PolygonResponse.self, from: data)
            let coordinates = polygonResponse.coordinates[0].map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            completion(.success(coordinates))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

/// Calculates the centroid (center point) of a polygon.
func calculateCentroid(of coordinates: [CLLocationCoordinate2D]) -> CLLocationCoordinate2D {
    var latitudeSum: Double = 0
    var longitudeSum: Double = 0

    for coordinate in coordinates {
        latitudeSum += coordinate.latitude
        longitudeSum += coordinate.longitude
    }

    let centroidLatitude = latitudeSum / Double(coordinates.count)
    let centroidLongitude = longitudeSum / Double(coordinates.count)

    return CLLocationCoordinate2D(latitude: centroidLatitude, longitude: centroidLongitude)
}

// MARK: - LoginResponse Model
struct LoginResponse: Decodable {
    let message: String
    let user_id: Int? // Optional, depending on your server response
}

// MARK: - RegisterResponse Model
struct RegisterResponse: Decodable {
    let message: String?
    let error: String?
}
