import CoreLocation
import Foundation
import Observation

@Observable
final class PerformanceService {
    private let service: LocationService

    private(set) var isArmed = false
    private(set) var isTiming = false
    private(set) var currentSpeedKmh: Double = 0
    private(set) var result: TimeInterval?

    private var startDate: Date?

    init(service: LocationService) {
        self.service = service
    }

    func arm() {
        result = nil
        isTiming = false
        startDate = nil
        currentSpeedKmh = 0
        isArmed = true
        service.onUpdate = { [weak self] location in
            self?.handle(location)
        }
        service.requestPermission()
        service.start()
    }

    func cancel() {
        isArmed = false
        isTiming = false
        startDate = nil
        service.onUpdate = nil
        service.stop()
    }

    private func handle(_ location: CLLocation) {
        currentSpeedKmh = max(0, location.speed) * 3.6

        if isTiming {
            if currentSpeedKmh >= 100 {
                if let startDate {
                    result = Date.now.timeIntervalSince(startDate)
                }
                isTiming = false
                isArmed = false
                service.onUpdate = nil
                service.stop()
            }
        } else if isArmed, currentSpeedKmh >= 2 {
            isTiming = true
            startDate = .now
        }
    }
}
