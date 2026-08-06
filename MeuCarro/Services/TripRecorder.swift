import CoreLocation
import Foundation
import Observation

@Observable
final class TripRecorder {
    private let service: LocationService

    private(set) var points: [TripPoint] = []
    private(set) var distanceKm: Double = 0
    private(set) var maxSpeedKmh: Double = 0
    private(set) var startDate: Date?
    private(set) var isRecording = false

    private var lastLocation: CLLocation?

    init(service: LocationService) {
        self.service = service
    }

    var currentLocation: CLLocation? { service.lastLocation }

    var elapsed: TimeInterval {
        guard let startDate else { return 0 }
        return Date.now.timeIntervalSince(startDate)
    }

    var avgSpeedKmh: Double {
        guard elapsed > 0 else { return 0 }
        return distanceKm / (elapsed / 3600)
    }

    var latestPoint: TripPoint? { points.last }

    func start() {
        points = []
        distanceKm = 0
        maxSpeedKmh = 0
        lastLocation = service.lastLocation
        startDate = .now
        isRecording = true
        service.onUpdate = { [weak self] location in
            self?.handle(location)
        }
        service.requestPermission()
        service.start()
    }

    func stop() -> Trip? {
        service.onUpdate = nil
        service.stop()
        isRecording = false
        guard let startDate, points.count > 1 else { return nil }
        let end = Date.now
        let duration = end.timeIntervalSince(startDate)
        return Trip(
            startDate: startDate,
            endDate: end,
            distanceKm: distanceKm,
            maxSpeedKmh: maxSpeedKmh,
            avgSpeedKmh: distanceKm / max(duration / 3600, 0.001),
            points: points
        )
    }

    private func handle(_ location: CLLocation) {
        guard isRecording else { return }
        let speedKmh = max(0, location.speed) * 3.6
        maxSpeedKmh = max(maxSpeedKmh, speedKmh)

        if let last = lastLocation {
            let delta = last.distance(from: location)
            if delta > 3 {
                distanceKm += delta / 1000
            }
        }
        lastLocation = location

        points.append(TripPoint(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timestamp: location.timestamp,
            speed: speedKmh,
            altitude: location.altitude
        ))
    }
}
