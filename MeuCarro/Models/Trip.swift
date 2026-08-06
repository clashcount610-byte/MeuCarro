import Foundation
import SwiftData

@Model
final class Trip {
    var startDate: Date
    var endDate: Date
    var distanceKm: Double
    var maxSpeedKmh: Double
    var avgSpeedKmh: Double
    var title: String
    var pointsData: Data

    init(
        startDate: Date,
        endDate: Date,
        distanceKm: Double,
        maxSpeedKmh: Double,
        avgSpeedKmh: Double,
        title: String = "",
        points: [TripPoint] = []
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.distanceKm = distanceKm
        self.maxSpeedKmh = maxSpeedKmh
        self.avgSpeedKmh = avgSpeedKmh
        self.title = title
        self.pointsData = (try? JSONEncoder().encode(points)) ?? Data()
    }

    var points: [TripPoint] {
        (try? JSONDecoder().decode([TripPoint].self, from: pointsData)) ?? []
    }

    var duration: TimeInterval { max(endDate.timeIntervalSince(startDate), 0) }
}
