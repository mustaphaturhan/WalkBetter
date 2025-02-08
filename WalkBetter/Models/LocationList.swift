import Foundation
import SwiftData

@Model
class LocationList {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Location.list) var locations: [Location]
    var createdAt: Date
    var isOptimized: Bool

    static let minLocations = 3
    static let maxLocations = 15

    init(name: String) {
        self.name = name
        self.locations = []
        self.createdAt = Date()
        self.isOptimized = false
    }

    var sortedLocations: [Location] {
        locations.sorted { $0.order < $1.order }
    }

    var canOptimize: Bool {
        locations.count >= LocationList.minLocations
    }

    var canAddMoreLocations: Bool {
        locations.count < LocationList.maxLocations
    }
}
