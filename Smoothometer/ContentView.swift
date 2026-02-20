import SwiftUI

struct ContentView: View {
    @State private var motion = MotionManager()
    @State private var settings = AppSettings()
    @State private var isSettingsPresented = false
    @State private var isBreached = false
    @State private var alertManager: AlertManager?
    @State private var isCalibrating = true

    private var maxDotTravel: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    private var dotOffset: CGSize {
        let x = motion.calibratedX.clamped(to: -2.0...2.0)
        let y = motion.calibratedY.clamped(to: -2.0...2.0)
        return CGSize(
            width:  x * maxDotTravel,
            height: -y * maxDotTravel
        )
    }

    private var dotDistanceFromCenter: Double {
        sqrt(dotOffset.width * dotOffset.width + dotOffset.height * dotOffset.height)
    }

    private var breachThreshold: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            GaugePadView(
                dotOffset: dotOffset,
                isBreached: isBreached,
                settings: settings
            )

            // Gear icon — hidden during calibration
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

            // Calibrating overlay — covers the gauge while the filter settles
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
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheetView(settings: settings, onRecalibrate: {
                motion.calibrate()
            })
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            alertManager = AlertManager(settings: settings)
            motion.start()
            UIApplication.shared.isIdleTimerDisabled = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                motion.calibrate()
                withAnimation(.easeOut(duration: 0.4)) {
                    isCalibrating = false
                }
            }
        }
        .onDisappear {
            motion.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: dotDistanceFromCenter) { _, distance in
            let breached = distance >= breachThreshold
            isBreached = breached
            if breached {
                alertManager?.triggerIfReady()
            }
        }
    }
}

#Preview {
    ContentView()
}
