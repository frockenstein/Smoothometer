import CoreLocation
import Foundation

/// A single recorded instance of the dot breaching the threshold ring.
///
/// Stores the GPS coordinates and timestamp so each event can be plotted
/// as a marker on the drive map.
///
/// CLLocationCoordinate2D doesn't conform to Codable natively, so latitude
/// and longitude are stored as plain Doubles and the coordinate is computed.
struct BreachEvent: Identifiable, Codable {

    /// Stable unique identifier used by ForEach in the map view.
    let id: UUID

    /// GPS latitude of the breach location in decimal degrees.
    let latitude: Double

    /// GPS longitude of the breach location in decimal degrees.
    let longitude: Double

    /// Wall-clock time when the breach was detected.
    let timestamp: Date

    /// Convenience accessor returning the coordinate pair as a CoreLocation type,
    /// suitable for use with MapKit annotations and polylines.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
