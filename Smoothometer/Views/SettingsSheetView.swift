import SwiftUI
import AudioToolbox

/// Bottom sheet presented when the driver taps the gear icon.
///
/// Sections:
///   - Alert Sound  — pick from a list of built-in system sounds + preview button
///   - Haptics      — toggle vibration on/off
///   - Sensitivity  — sigmoid curve steepness (how aggressively the dot reacts)
///   - Threshold Ring — ring radius slider (also adjustable via pinch on the main screen)
///   - Calibration  — re-zero the dot when the mount angle changes
///   - How to use   — brief usage reminder
struct SettingsSheetView: View {

    /// Two-way binding to the shared settings object.
    /// @Bindable is required (instead of plain var) to create $settings.xxx bindings
    /// for Picker, Toggle, and Slider.
    @Bindable var settings: AppSettings

    /// Closure called when the driver taps "Re-zero Dot".
    /// Defined in ContentView so it has access to MotionManager.calibrate().
    var onRecalibrate: () -> Void

    /// SwiftUI environment value used to close this sheet programmatically.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Alert Sound
                Section("Alert Sound") {
                    // Picker writes directly to settings.selectedSoundID via binding.
                    Picker("Sound", selection: $settings.selectedSoundID) {
                        ForEach(settings.availableSounds) { sound in
                            Text(sound.name).tag(sound.id)
                        }
                    }
                    .pickerStyle(.menu)

                    // Let the driver audition the sound before committing.
                    Button("Preview Sound") {
                        settings.previewSound()
                    }
                }

                // MARK: Haptics
                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: $settings.hapticsEnabled)
                }

                // MARK: Sensitivity
                Section("Sensitivity") {
                    HStack {
                        Text("Sensitivity")
                        Spacer()
                        // Live readout of the current integer value.
                        Text("\(Int(settings.sensitivity))")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    // Controls the k constant in the sigmoid response curve.
                    // Low = subtle reaction; High = very responsive to small forces.
                    Slider(value: $settings.sensitivity, in: 5...15, step: 1)
                    HStack {
                        Text("Subtle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Aggressive")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // MARK: Threshold Ring
                Section("Threshold Ring") {
                    HStack {
                        Text("Radius")
                        Spacer()
                        // Live readout in points as the slider moves.
                        Text("\(Int(settings.ringRadius)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    // The ring can also be resized by pinching the main gauge screen.
                    Slider(value: $settings.ringRadius, in: 20...200, step: 1)
                }

                // MARK: Calibration
                Section("Calibration") {
                    // Calls MotionManager.calibrate() via the closure passed from ContentView,
                    // then dismisses the sheet so the driver sees the re-zeroed dot immediately.
                    Button {
                        onRecalibrate()
                        dismiss()
                    } label: {
                        Label("Re-zero Dot", systemImage: "scope")
                    }
                    Text("Park the car, wait a moment, then tap to re-zero the dot to center. Also done automatically 2 seconds after launch.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: How to use
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
