import CoreLocation
import Foundation
import Combine

final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var lastLocation: CLLocation?
    var onUpdate: ((CLLocation) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func start() {
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        onUpdate?(location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro de localização: \(error.localizedDescription)")
    }
}
