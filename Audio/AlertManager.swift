import AudioToolbox
import UIKit

final class AlertManager: ObservableObject {
    private let cooldownDuration: TimeInterval = 2.0
    private var lastAlertTime: Date = .distantPast
    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Call every frame when breach is detected. Internally rate-limits to cooldownDuration.
    func triggerIfReady() {
        let now = Date()
        guard now.timeIntervalSince(lastAlertTime) >= cooldownDuration else { return }
        lastAlertTime = now
        playSound()
        if settings.hapticsEnabled {
            triggerHaptic()
        }
    }

    private func playSound() {
        AudioServicesPlaySystemSound(SystemSoundID(settings.selectedSoundID))
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
}
