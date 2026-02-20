import SwiftUI
import AudioToolbox
import Observation

@Observable
final class AppSettings {

    static let minRingRadius: Double = 50.0
    static let maxRingRadius: Double = 220.0

    var ringRadius: Double {
        didSet { UserDefaults.standard.set(ringRadius, forKey: "ringRadius") }
    }

    var selectedSoundID: Int {
        didSet { UserDefaults.standard.set(selectedSoundID, forKey: "selectedSoundID") }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }

    struct SoundOption: Identifiable {
        let id: Int
        let name: String
    }

    let availableSounds: [SoundOption] = [
        SoundOption(id: 1052, name: "Tock"),
        SoundOption(id: 1057, name: "Chime"),
        SoundOption(id: 1005, name: "New Mail"),
        SoundOption(id: 1016, name: "Tweet"),
        SoundOption(id: 1108, name: "Glass"),
        SoundOption(id: 1011, name: "Sent Message"),
    ]

    init() {
        ringRadius   = UserDefaults.standard.object(forKey: "ringRadius")    as? Double ?? 120.0
        selectedSoundID = UserDefaults.standard.object(forKey: "selectedSoundID") as? Int ?? 1052
        hapticsEnabled  = UserDefaults.standard.object(forKey: "hapticsEnabled")  as? Bool ?? true
    }

    func resetRingRadius() {
        ringRadius = 120.0
    }

    func previewSound() {
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
    }
}
