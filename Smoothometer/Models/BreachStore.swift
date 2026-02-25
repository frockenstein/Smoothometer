import Foundation
import Observation

/// Persists the list of breach events across app launches.
///
/// Events are saved as a JSON file in the app's Documents directory so they
/// accumulate over multiple drives. The user can wipe the history via the
/// "Clear History" button in the map view.
@Observable
final class BreachStore {

    // MARK: - Public state

    /// All recorded breach events, ordered oldest → newest.
    /// Observed by DriveMapView to update the map annotations reactively.
    private(set) var events: [BreachEvent] = []

    // MARK: - Persistence

    /// URL of the JSON file where events are saved, inside the app sandbox.
    private static let saveURL: URL = {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("breachEvents.json")
    }()

    // MARK: - Init

    /// Load any previously saved events from disk when the store is created.
    init() {
        load()
    }

    // MARK: - Public interface

    /// Append a new breach event at the given GPS coordinate and save to disk.
    /// Called by ContentView on the false → true transition of isBreached.
    func record(latitude: Double, longitude: Double) {
        let event = BreachEvent(
            id: UUID(),
            latitude: latitude,
            longitude: longitude,
            timestamp: Date()
        )
        events.append(event)
        save()
    }

    /// Remove all stored breach events and delete the save file.
    /// Triggered by the "Clear History" button in the map view.
    func clearAll() {
        events = []
        try? FileManager.default.removeItem(at: Self.saveURL)
    }

    // MARK: - Private persistence

    /// Encode the current events array to JSON and write it to disk.
    private func save() {
        guard let data = try? JSONEncoder().encode(events) else { return }
        try? data.write(to: Self.saveURL, options: .atomic)
    }

    /// Read and decode the events JSON file from disk.
    /// Silently fails if the file doesn't exist yet (first launch).
    private func load() {
        guard let data = try? Data(contentsOf: Self.saveURL),
              let saved = try? JSONDecoder().decode([BreachEvent].self, from: data)
        else { return }
        events = saved
    }
}
