import SwiftUI
import CoreLocation

/// Root view of Smoothometer. Owns all state and wires the subsystems together.
///
/// Responsibilities:
///   - Holds MotionManager, LocationManager, AppSettings, AlertManager, BreachStore
///   - Runs a spring-damper physics simulation to move the dot with inertia
///   - Detects when the dot breaches the threshold ring, fires the alert, and records the location
///   - Shows a calibration overlay on launch while the sensor filter settles
///   - Keeps the screen awake while active (idle timer disabled)
struct ContentView: View {

    // MARK: - State

    /// Streams accelerometer data and exposes calibrated X/Y G-force values.
    @State private var motion = MotionManager()

    /// Streams GPS location and accumulates the driven route polyline.
    @State private var locationManager = LocationManager()

    /// User-adjustable preferences (ring size, sensitivity, sound, haptics).
    @State private var settings = AppSettings()

    /// Persists the list of GPS coordinates where breaches occurred.
    @State private var breachStore = BreachStore()

    /// Controls visibility of the settings bottom sheet.
    @State private var isSettingsPresented = false

    /// Controls visibility of the drive map full-screen cover.
    @State private var isMapPresented = false

    /// True while the dot's edge is at or beyond the threshold ring edge.
    /// Drives the ring's breach colour and triggers AlertManager.
    @State private var isBreached = false

    /// Fires audio/haptic alerts with cooldown. Created in onAppear after
    /// settings is fully initialised, so it holds the correct settings reference.
    @State private var alertManager: AlertManager?

    /// True for the first 2 seconds while the low-pass filter settles.
    /// Hides the gauge and shows a "Calibrating" overlay instead.
    @State private var isCalibrating = true

    /// When true, the live debug HUD is shown at the bottom of the screen.
    /// Toggled by the waveform button in the toolbar. Dev/tuning use only.
    @State private var showDebugHUD = false

    // MARK: - Physics state

    /// Normalised dot position on the X axis (−1 … 1, right = positive).
    /// Driven by the spring-damper simulation, not mapped directly from the accelerometer.
    @State private var dotX: Double = 0.0

    /// Normalised dot position on the Y axis (−1 … 1, up = positive).
    @State private var dotY: Double = 0.0

    /// Current dot velocity along X, in normalised units per second.
    @State private var velX: Double = 0.0

    /// Current dot velocity along Y, in normalised units per second.
    @State private var velY: Double = 0.0

    // MARK: - Computed geometry

    /// Maximum distance the dot centre can travel from the screen centre, in points.
    /// Set so the dot edge (centre + radius) just reaches the ring edge at full scale (1.0).
    private var maxDotTravel: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    // MARK: - Physics simulation

    /// Advances the spring-damper model one frame (Δt = 1/60 s).
    ///
    /// Model:
    ///   force    = calibratedAccel × forceFactor   — accelerometer drives the dot
    ///   velΔ     = (force − springK × pos) × dt    — spring pulls back to centre
    ///   vel     *= damping                          — friction / fluid resistance
    ///   pos     += vel × dt                         — integrate position
    ///
    /// Feel targets:
    ///   - Sluggish at rest, like liquid in a cup — dot doesn't snap instantly
    ///   - Builds momentum under sustained G so it slides toward the ring
    ///   - Drifts back to centre slowly once force is removed
    ///
    /// Tuning knobs:
    ///   forceFactor = sensitivity × 1.2  (scaled up to match stiffer spring)
    ///   springK     = 5.0   (2× stiffer — snaps back to centre quickly)
    ///   damping     = 0.94  (less friction — crisper response, more momentum)
    private func stepPhysics() {
        let dt          = 1.0 / 60.0
        let forceFactor = settings.sensitivity * 1.2   // scaled up to match stiffer spring
        let springK     = 5.0                           // 2× stiffer — snaps back to centre quickly
        let damping     = 0.94                          // less friction — crisper response, more momentum

        // Accelerometer force minus spring restoring force → velocity change
        velX += (motion.calibratedX * forceFactor - springK * dotX) * dt
        velY += (motion.calibratedY * forceFactor - springK * dotY) * dt

        // Apply damping — models friction and fluid drag
        velX *= damping
        velY *= damping

        // Integrate velocity into position
        dotX += velX * dt
        dotY += velY * dt

        // Hard stop at ring boundary — kill outward velocity so the dot
        // doesn't stick to the edge while the spring is recalling it.
        if dotX >  1.0 { dotX =  1.0; velX = min(velX, 0) }
        if dotX < -1.0 { dotX = -1.0; velX = max(velX, 0) }
        if dotY >  1.0 { dotY =  1.0; velY = min(velY, 0) }
        if dotY < -1.0 { dotY = -1.0; velY = max(velY, 0) }
    }

    /// Resets physics to the resting state — called on calibration so the dot
    /// snaps to centre rather than carrying stale velocity into the new baseline.
    private func resetPhysics() {
        dotX = 0; dotY = 0; velX = 0; velY = 0
    }

    // MARK: - Dot position

    /// Screen-space offset of the dot from the gauge centre, in points.
    /// Derived from physics state (dotX, dotY) scaled by maxDotTravel.
    /// Y is negated because SwiftUI's Y axis increases downward, but positive
    /// accelerometer Y (braking) should push the dot toward the top of the screen.
    private var dotOffset: CGSize {
        CGSize(
            width:  dotX * maxDotTravel,
            height: -dotY * maxDotTravel
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
        ZStack {

            // Main gauge — always rendered so it's ready the instant calibration ends.
            GaugePadView(
                dotOffset: dotOffset,
                isBreached: isBreached,
                settings: settings
            )

            // Top button bar — map icon top-left, gear icon top-right.
            // Hidden during calibration so the driver isn't distracted while holding still.
            if !isCalibrating {
                VStack {
                    HStack {
                        // Map button — opens the drive map full-screen cover.
                        Button {
                            isMapPresented = true
                        } label: {
                            Image(systemName: "map.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(20)
                        }

                        Spacer()

                        // Debug HUD toggle — shows live accelerometer/physics data.
                        Button {
                            showDebugHUD.toggle()
                        } label: {
                            Image(systemName: "waveform.path.ecg")
                                .font(.title2)
                                .foregroundStyle(showDebugHUD ? Color.yellow : Color.white.opacity(0.6))
                                .padding(20)
                        }

                        // Settings button — opens the settings bottom sheet.
                        Button {
                            isSettingsPresented = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(20)
                        }
                    }
                    Spacer()
                }
                .transition(.opacity)
            }

            // Live debug HUD — pinned to the bottom of the screen.
            // Shows raw G-force, physics state, and distance vs. threshold
            // so you can correlate what you feel in the car with the numbers.
            if showDebugHUD && !isCalibrating {
                VStack {
                    Spacer()
                    DebugHUDView(
                        calibX:    motion.calibratedX,
                        calibY:    motion.calibratedY,
                        dotX:      dotX,
                        dotY:      dotY,
                        velX:      velX,
                        velY:      velY,
                        distance:  dotDistanceFromCenter,
                        threshold: breachThreshold,
                        isBreached: isBreached
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
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
                resetPhysics()              // clear velocity so the dot doesn't carry momentum into new baseline
                motion.calibrate()
            })
            .presentationDetents([.medium, .large])
        }

        // Drive map — full-screen so the map has maximum space.
        .fullScreenCover(isPresented: $isMapPresented) {
            DriveMapView(locationManager: locationManager, breachStore: breachStore)
        }

        .onAppear {
            // Start the accelerometer stream.
            motion.start()
            // Request location permission and start GPS tracking.
            locationManager.requestAndStart()
            // Prevent the screen from sleeping while the app is open.
            UIApplication.shared.isIdleTimerDisabled = true

            // Wait 2 seconds for the low-pass filter to converge on the true
            // resting values, then snapshot those as the calibration baseline,
            // reset physics to rest, and fade out the overlay.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                motion.calibrate()
                resetPhysics()              // clear any pre-calibration drift
                // Create the alert manager only now — keeps it nil during the settling
                // window so no sound or haptic can fire before the dot is at zero.
                alertManager = AlertManager(settings: settings)
                withAnimation(.easeOut(duration: 0.4)) {
                    isCalibrating = false
                }
            }
        }

        .onDisappear {
            motion.stop()
            locationManager.stop()
            // Re-enable the idle timer so the screen can sleep normally
            // when the app is in the background or closed.
            UIApplication.shared.isIdleTimerDisabled = false
        }

        // Advance physics on every accelerometer sample (60 Hz).
        // Skipped while calibrating so stale sensor data doesn't pre-load velocity.
        .onChange(of: motion.calibratedX) { _, _ in
            guard !isCalibrating else { return }
            stepPhysics()
        }

        // Evaluated every frame after physics updates dotX/dotY.
        // Updates breach state and fires the alert when the dot reaches the ring.
        .onChange(of: dotDistanceFromCenter) { _, distance in
            let breached = distance >= breachThreshold
            isBreached = breached
            if breached {
                // AlertManager internally rate-limits to one alert per 2 seconds.
                alertManager?.triggerIfReady()
            }
        }

        // Watch for the false → true transition of isBreached.
        // Only records the breach location on the leading edge (first frame of contact),
        // not on every subsequent frame while the dot stays outside the ring.
        .onChange(of: isBreached) { wasBreached, nowBreached in
            if !wasBreached && nowBreached,
               let location = locationManager.currentLocation {
                breachStore.record(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
