import SwiftUI
import AudioToolbox

final class AppSettings: ObservableObject {

    // Ring radius in SwiftUI points. Default 120pt is visually comfortable.
    @AppStorage("ringRadius") var ringRadius: Double = 120.0

    // Bounds for pinch gesture clamping
    static let minRingRadius: Double = 50.0
    static let maxRingRadius: Double = 220.0

    // SystemSoundID stored as Int for @AppStorage compatibility
    @AppStorage("selectedSoundID") var selectedSoundID: Int = 1052

    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true

    struct SoundOption: Identifiable {
        let id: Int  // SystemSoundID raw value
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

    func resetRingRadius() {
        ringRadius = 120.0
    }

    func previewSound() {
        AudioServicesPlaySystemSound(SystemSoundID(selectedSoundID))
    }
}
