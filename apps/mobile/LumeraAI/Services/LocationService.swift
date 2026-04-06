import Foundation
import CoreLocation
import Combine

// MARK: - Location Service

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var heading: CLHeading?
    @Published private(set) var gpsQuality: GPSQuality = .unavailable
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    enum GPSQuality {
        case good        // accuracy <= 3m
        case moderate    // accuracy <= 8m
        case poor        // accuracy <= 15m
        case unavailable
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = 0.5
        manager.headingFilter = 2.0
        manager.activityType = .fitness
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    private func updateQuality(from location: CLLocation) {
        let accuracy = location.horizontalAccuracy
        if accuracy < 0 {
            gpsQuality = .unavailable
        } else if accuracy <= 3.0 {
            gpsQuality = .good
        } else if accuracy <= 8.0 {
            gpsQuality = .moderate
        } else if accuracy <= 15.0 {
            gpsQuality = .poor
        } else {
            gpsQuality = .unavailable
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.updateQuality(from: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            self.heading = newHeading
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.gpsQuality = .unavailable
        }
    }
}
