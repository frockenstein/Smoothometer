import SwiftUI
import AudioToolbox
import Observation

/// Persistent user preferences for Smoothometer.
///
/// All properties are stored in UserDefaults via didSet so values survive
/// app restarts. The @Observable macro means any SwiftUI view that reads
/// a property will automatically re-render when it changes.
@Observable
final class AppSettings {

    // MARK: - Ring size bounds (used by both the slider and the pinch gesture)

    /// Minimum allowed ring radius in SwiftUI points.
    static let minRingRadius: Double = 20.0

    /// Maximum allowed ring radius in SwiftUI points.
    static let maxRingRadius: Double = 200.0

    // MARK: - Stored settings

    /// Radius of the threshold ring in SwiftUI points.
    /// The dot triggers an alert when it touches this ring.
    /// Persisted so the user's preferred sensitivity survives restarts.
    var ringRadius: Double {
        didSet { UserDefaults.standard.set(ringRadius, forKey: "ringRadius") }
    }

    /// Raw SystemSoundID integer for the alert sound.
    /// Stored as Int because @Observable + UserDefaults works cleanly with primitives.
    var selectedSoundID: Int {
        didSet { UserDefaults.standard.set(selectedSoundID, forKey: "selectedSoundID") }
    }

    /// Whether to fire a haptic buzz alongside the audio alert.
    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    /// Controls how aggressively small G-forces move the dot (1 = subtle, 10 = very responsive).
    /// Used as the steepness constant k in the sigmoid response curve: tanh(k · x · |x|).
    var sensitivity: Double {
        didSet { UserDefaults.standard.set(sensitivity, forKey: "sensitivity") }
    }

    // MARK: - Sound catalogue

    /// A selectable alert sound, identified by its SystemSoundID.
    struct SoundOption: Identifiable {
        /// Raw SystemSoundID value — also used as the stable list identity.
        let id: Int
        /// Human-readable name shown in the picker.
        let name: String
    }

    /// The fixed list of system sounds offered to the user in settings.
    /// SystemSoundIDs are built into iOS and require no bundled audio files.
    let availableSounds: [SoundOption] = [
        SoundOption(id: 1052, name: "Tock"),
        SoundOption(id: 1057, name: "Chime"),
        SoundOption(id: 1005, name: "New Mail"),
        SoundOption(id: 1016, name: "Tweet"),
        SoundOption(id: 1108, name: "Glass"),
        SoundOption(id: 1011, name: "Sent Message"),
    ]

    // MARK: - Init

    /// Load all settings from UserDefaults, falling back to sensible defaults
    /// if no value has been stored yet (i.e. first launch).
    init() {
        ringRadius      = UserDefaults.standard.object(forKey: "ringRadius")      as? Double ?? 120.0
        selectedSoundID = UserDefaults.standard.object(forKey: "selectedSoundID") as? Int    ?? 1052
        hapticsEnabled  = UserDefaults.standard.object(forKey: "hapticsEnabled")  as? Bool   ?? true
        sensitivity     = UserDefaults.standard.object(forKey: "sensitivity")     as? Double ?? 5.0
    }

    // MARK: - Actions

    /// Reset the threshold ring back to its default size (120 pt).
    func resetRingRadius() {
        ringRadius = 120.0
    }

    /// Immediately play the currently selected alert sound.
    /// Used by the "Preview Sound" button in settings.
    func previewSound() {
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
    }
}
