//
//  LocationService.swift
//  GlassCast
//
//  Created by Claude on 20/01/26.
//

import Foundation
import CoreLocation
import Combine

enum LocationError: LocalizedError {
    case denied
    case restricted
    case unknown

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access denied. Please enable location in Settings."
        case .restricted:
            return "Location access restricted"
        case .unknown:
            return "Unable to get location"
        }
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func getCurrentLocation() async throws -> CLLocation {
        if authorizationStatus == .notDetermined {
            requestPermission()
            // Wait for authorization
            try await Task.sleep(for: .seconds(1))
        }

        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            if authorizationStatus == .denied {
                throw LocationError.denied
            } else if authorizationStatus == .restricted {
                throw LocationError.restricted
            } else {
                throw LocationError.unknown
            }
        }

        locationManager.requestLocation()

        // Wait for location update
        for _ in 0..<10 {
            try await Task.sleep(for: .milliseconds(500))
            if let location = currentLocation {
                return location
            }
        }

        throw LocationError.unknown
    }

    func getCurrentLocationCity() async -> String? {
        do {
            let location = try await getCurrentLocation()
            let geocoder = CLGeocoder()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            if let city = placemarks.first?.locality {
                return city
            }
            return nil
        } catch {
            print("Failed to get city from location: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

extension LocationService: CLLocationManagerDelegate {
}
