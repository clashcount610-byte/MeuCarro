import CoreLocation
import Foundation

struct TripPoint: Codable, Hashable {
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var speed: Double
    var altitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
