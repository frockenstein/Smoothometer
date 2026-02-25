import SwiftUI
import MapKit
import CoreLocation

/// Full-screen map showing the route driven this session and all recorded breach locations.
///
/// Route (blue polyline): GPS path accumulated by LocationManager since app launch.
///                        Resets each session — not persisted.
///
/// Breach dots (red): Every point where the dot touched the threshold ring.
///                    Persisted across sessions by BreachStore.
///
/// The map follows the user's current location using the built-in UserAnnotation
/// and standard MapKit location controls.
struct DriveMapView: View {

    /// Provides the in-session GPS route polyline and current location.
    var locationManager: LocationManager

    /// Provides the persisted list of breach event coordinates.
    var breachStore: BreachStore

    /// Used to dismiss this sheet programmatically from the toolbar buttons.
    @Environment(\.dismiss) private var dismiss

    /// Controls whether the "Clear History" confirmation alert is showing.
    @State private var showingClearConfirm = false

    var body: some View {
        NavigationStack {
            Map {
                // --- Driven route ---
                // Only draw the polyline once we have at least two points;
                // a single point produces a zero-length line.
                if locationManager.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(.blue.opacity(0.7), lineWidth: 4)
                }

                // --- Breach markers ---
                // Each red dot marks a spot where the driver braked/cornered
                // hard enough to touch the threshold ring.
                ForEach(breachStore.events) { event in
                    Annotation("", coordinate: event.coordinate) {
                        ZStack {
                            // Outer glow ring for visibility on varied map backgrounds.
                            Circle()
                                .fill(.red.opacity(0.25))
                                .frame(width: 22, height: 22)
                            // Solid inner dot.
                            Circle()
                                .fill(.red)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                // Built-in blue dot showing the driver's current GPS position.
                UserAnnotation()
            }
            // Show the standard MapKit compass, scale bar, and locate button.
            .mapControls {
                MapCompass()
                MapScaleView()
                MapUserLocationButton()
            }
            .navigationTitle("Drive Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }

                ToolbarItem(placement: .destructiveAction) {
                    // Confirm before wiping history since it can't be undone.
                    Button("Clear History") {
                        showingClearConfirm = true
                    }
                    .foregroundStyle(.red)
                    .disabled(breachStore.events.isEmpty)
                }
            }
            // Stats footer — gives a quick summary without needing to count dots.
            .safeAreaInset(edge: .bottom) {
                statsBar
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Clear all \(breachStore.events.count) breach event(s)?",
            isPresented: $showingClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                breachStore.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Subviews

    /// Thin dark bar at the bottom showing session and history stats.
    private var statsBar: some View {
        HStack(spacing: 24) {
            Label("\(locationManager.routeCoordinates.count) GPS pts", systemImage: "location.fill")
            Divider().frame(height: 14)
            Label("\(breachStore.events.count) breach(es)", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(breachStore.events.isEmpty ? Color.secondary : Color.red)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}
