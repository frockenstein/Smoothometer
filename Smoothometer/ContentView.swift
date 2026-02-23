import SwiftUI

/// Root view of Smoothometer. Owns all state and wires the subsystems together.
///
/// Responsibilities:
///   - Holds the MotionManager, AppSettings, and AlertManager instances
///   - Converts raw calibrated G-force values into a dot offset using the
///     sigmoid response curve
///   - Detects when the dot breaches the threshold ring and fires the alert
///   - Shows a calibration overlay on launch while the sensor filter settles
///   - Keeps the screen awake while active (idle timer disabled)
struct ContentView: View {

    // MARK: - State

    /// Streams accelerometer data and exposes calibrated X/Y G-force values.
    @State private var motion = MotionManager()

    /// User-adjustable preferences (ring size, sensitivity, sound, haptics).
    @State private var settings = AppSettings()

    /// Controls visibility of the settings bottom sheet.
    @State private var isSettingsPresented = false

    /// True while the dot's edge is at or beyond the threshold ring edge.
    /// Drives the ring's breach colour and triggers AlertManager.
    @State private var isBreached = false

    /// Fires audio/haptic alerts with cooldown. Created in onAppear after
    /// settings is fully initialised, so it holds the correct settings reference.
    @State private var alertManager: AlertManager?

    /// True for the first 2 seconds while the low-pass filter settles.
    /// Hides the gauge and shows a "Calibrating" overlay instead.
    @State private var isCalibrating = true

    // MARK: - Computed geometry

    /// Maximum distance the dot centre can travel from the screen centre, in points.
    /// Set so the dot edge (centre + radius) just reaches the ring edge at full scale (1.0).
    private var maxDotTravel: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    // MARK: - Response curve

    /// Maps a raw calibrated G-force value to a normalised dot position (−1 … 1)
    /// using a sigmoid-shaped response curve:
    ///
    ///   shaped = x · |x|   →  sign-preserving quadratic: slow near zero, grows quickly
    ///   output = tanh(k · shaped)  →  smooth saturation toward ±1 at high G
    ///
    /// This mimics how a car feels — small bumps barely register, genuine braking
    /// or cornering forces produce a clear movement, and the dot never flies off screen.
    /// `k` (sensitivity 1–10) controls how steeply the middle section rises.
    private func applyResponse(_ value: Double) -> Double {
        let k = settings.sensitivity          // user-controlled steepness (1–10)
        let shaped = value * abs(value)       // sign(x)·x²: compresses tiny inputs
        return tanh(k * shaped)              // saturates smoothly toward ±1
    }

    // MARK: - Dot position

    /// Screen-space offset of the dot from the centre of the gauge, in points.
    /// X maps to lateral force (right = positive), Y is negated because SwiftUI's
    /// Y axis increases downward while braking (positive accelerometer Y) should
    /// move the dot upward toward the top of the screen.
    private var dotOffset: CGSize {
        let x = applyResponse(motion.calibratedX)
        let y = applyResponse(motion.calibratedY)
        return CGSize(
            width:  x * maxDotTravel,
            height: -y * maxDotTravel
        )
    }

    /// Euclidean distance from the gauge centre to the current dot position, in points.
    /// Used each frame to check whether the dot has reached the threshold ring.
    private var dotDistanceFromCenter: Double {
        sqrt(dotOffset.width * dotOffset.width + dotOffset.height * dotOffset.height)
    }

    /// Distance at which the outer edge of the dot meets the inner edge of the ring.
    /// Breach is detected when dotDistanceFromCenter ≥ this value.
    private var breachThreshold: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {

            // Main gauge — always rendered so it's ready the instant calibration ends.
            GaugePadView(
                dotOffset: dotOffset,
                isBreached: isBreached,
                settings: settings
            )

            // Gear icon fades in after calibration so the driver isn't prompted
            // to open settings while the dot is still settling.
            if !isCalibrating {
                Button {
                    isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(20)
                }
                .transition(.opacity)
            }

            // Full-screen overlay shown for the first 2 seconds.
            // Hides the unsettled dot and tells the driver to hold still.
            if isCalibrating {
                ZStack {
                    Color.black.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.4)
                        Text("Calibrating")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text("Hold the phone still")
                            .foregroundStyle(.white.opacity(0.6))
                            .font(.subheadline)
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)

        // Settings sheet — medium detent by default, expandable to full height.
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheetView(settings: settings, onRecalibrate: {
                motion.calibrate()
            })
            .presentationDetents([.medium, .large])
        }

        .onAppear {
            // Wire up the alert manager with the live settings instance.
            alertManager = AlertManager(settings: settings)
            // Start the accelerometer stream.
            motion.start()
            // Prevent the screen from sleeping while the app is open.
            UIApplication.shared.isIdleTimerDisabled = true

            // Wait 2 seconds for the low-pass filter to converge on the true
            // resting values, then snapshot those as the calibration baseline
            // and fade out the overlay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                motion.calibrate()
                withAnimation(.easeOut(duration: 0.4)) {
                    isCalibrating = false
                }
            }
        }

        .onDisappear {
            motion.stop()
            // Re-enable the idle timer so the screen can sleep normally
            // when the app is in the background or closed.
            UIApplication.shared.isIdleTimerDisabled = false
        }

        // Evaluated every frame at 60 Hz while the accelerometer is running.
        // Updates breach state and fires the alert when the dot hits the ring.
        .onChange(of: dotDistanceFromCenter) { _, distance in
            let breached = distance >= breachThreshold
            isBreached = breached
            if breached {
                // AlertManager internally rate-limits to one alert per 2 seconds.
                alertManager?.triggerIfReady()
            }
        }
    }
}

#Preview {
    ContentView()
}
