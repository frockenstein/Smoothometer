import CoreLocation
import Observation

/// Streams GPS location data and accumulates the driven route for the current session.
///
/// The route (polyline) is in-memory only and resets on each app launch.
/// Breach event coordinates are recorded separately by BreachStore.
///
/// Requires NSLocationWhenInUseUsageDescription in the app's Info settings.
/// If the user denies permission, currentLocation stays nil and the route
/// stays empty — the map will still open but won't show a path.
@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {

    // MARK: - Public state

    /// The most recent GPS fix. Nil until the first update arrives or if permission is denied.
    var currentLocation: CLLocation?

    /// Ordered list of coordinates forming the route driven this session.
    /// Appended every time the device moves at least `distanceFilter` metres.
    var routeCoordinates: [CLLocationCoordinate2D] = []

    /// Current authorisation status, updated whenever the user changes their decision.
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Private

    /// Underlying CoreLocation manager. One instance per app is the recommended pattern.
    private let manager = CLLocationManager()

    // MARK: - Init

    override init() {
        super.init()
        manager.delegate = self
        /// Only append a new route point after moving at least 10 metres,
        /// keeping the coordinate array manageable on long drives.
        manager.distanceFilter = 10
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Public interface

    /// Request location permission and start streaming updates.
    /// Safe to call multiple times — CoreLocation ignores redundant start calls.
    func requestAndStart() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    /// Stop GPS updates. Called when the app moves to the background or is dismissed.
    func stop() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    /// Called each time a new GPS fix arrives (subject to distanceFilter).
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        routeCoordinates.append(location.coordinate)
    }

    /// Called when the user grants, denies, or changes their location permission.
    /// Starts updates automatically if permission is granted after a delay.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    /// Called if location updates fail (e.g. no GPS signal in a tunnel).
    /// Non-fatal — updates resume automatically when signal returns.
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        // Silently ignore transient errors; location resumes automatically.
    }
}
