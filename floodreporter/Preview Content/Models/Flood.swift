import Foundation

struct Flood: Identifiable, Codable {
    let id: Int
    let userId: Int
    let gpsLongitude: Double
    let gpsLatitude: Double
    let radius: Double
    let severity: Int
    let timeReported: String
    let username: String
    let title: String         // Add title property
    let description: String   // Add description property

    enum CodingKeys: String, CodingKey {
        case id = "flood_id"
        case userId = "user_id"
        case gpsLongitude = "gps_longitude"
        case gpsLatitude = "gps_latitude"
        case radius, severity
        case timeReported = "time_reported"
        case username, title, description // Include title and description in CodingKeys
    }
}
