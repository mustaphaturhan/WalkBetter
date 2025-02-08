import Foundation
import MapKit
import SwiftData

@Model
class Location {
    var name: String
    var latitude: Double
    var longitude: Double
    var order: Int
    var list: LocationList?

    init(name: String, latitude: Double, longitude: Double, order: Int = 0) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.order = order
        self.list = nil
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
