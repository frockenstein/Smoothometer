import SwiftUI
import AudioToolbox

struct SettingsSheetView: View {
    @Bindable var settings: AppSettings  // @Bindable needed for $settings.xxx bindings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Alert Sound") {
                    Picker("Sound", selection: $settings.selectedSoundID) {
                        ForEach(settings.availableSounds) { sound in
                            Text(sound.name).tag(sound.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Button("Preview Sound") {
                        settings.previewSound()
                    }
                }

                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                }

                Section("Threshold Ring") {
                    HStack {
                        Text("Current radius")
                        Spacer()
                        Text("\(Int(settings.ringRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Button("Reset to Default") {
                        settings.resetRingRadius()
                    }
                    .foregroundStyle(.red)
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("How to use")
                            .font(.headline)
                        Text("Mount your phone vertically on your dashboard, screen facing you. The dot moves in the direction of G-force. Pinch the screen to adjust the threshold ring size.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Smoothometer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
