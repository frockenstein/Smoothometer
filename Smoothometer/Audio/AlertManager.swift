import AudioToolbox
import UIKit

/// Fires audio and haptic alerts when the dot breaches the threshold ring.
///
/// Designed to be called every frame (60 Hz) during a breach, but internally
/// rate-limits alerts to one per `cooldownDuration` seconds so the driver
/// isn't bombarded with rapid repeating sounds.
final class AlertManager {

    // MARK: - Configuration

    /// Minimum time between successive alerts in seconds.
    /// Prevents the alert from firing repeatedly on every frame while the
    /// dot stays outside the ring.
    private let cooldownDuration: TimeInterval = 2.0

    /// Timestamp of the most recent fired alert.
    /// Initialised to .distantPast so the first breach always triggers immediately.
    private var lastAlertTime: Date = .distantPast

    /// Reference to user settings, read at alert time to pick the correct
    /// sound ID and check whether haptics are enabled.
    private let settings: AppSettings

    // MARK: - Init

    init(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Public interface

    /// Fire an alert if enough time has passed since the last one.
    /// Call this every frame while the dot is outside the threshold ring.
    func triggerIfReady() {
        let now = Date()
        // Bail out silently if still within the cooldown window.
        guard now.timeIntervalSince(lastAlertTime) >= cooldownDuration else { return }
        lastAlertTime = now
        playSound()
        if settings.hapticsEnabled {
            triggerHaptic()
        }
    }

    // MARK: - Private

    /// Play the user-selected system sound.
    /// AudioServicesPlaySystemSound respects the hardware ringer switch —
    /// if the phone is silenced, the sound won't play (haptics still will).
    private func playSound() {
        AudioServicesPlaySystemSound(SystemSoundID(settings.selectedSoundID))
    }

    /// Fire a UIKit notification haptic with "warning" intensity.
    /// prepare() is called immediately before use to minimise latency.
    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
