import SwiftUI

struct ContentView: View {
    @StateObject private var motion = MotionManager()
    @StateObject private var settings = AppSettings()
    @State private var isSettingsPresented = false
    @State private var isBreached = false
    @State private var alertManager: AlertManager?

    // Dot travel distance: dot edge reaches ring edge at 1.0g
    private var maxDotTravel: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    // Map accelerometer [-1, 1] to screen offset in points.
    // X: positive accelerometer X = right lateral force → dot moves right
    // Y: negate because SwiftUI Y increases downward, but braking (positive acc Y) should move dot up
    private var dotOffset: CGSize {
        let x = motion.filteredX.clamped(to: -2.0...2.0)
        let y = motion.filteredY.clamped(to: -2.0...2.0)
        return CGSize(
            width:  x * maxDotTravel,
            height: -y * maxDotTravel
        )
    }

    // Euclidean distance from center (in points)
    private var dotDistanceFromCenter: Double {
        sqrt(dotOffset.width * dotOffset.width + dotOffset.height * dotOffset.height)
    }

    // Breach: dot edge has reached or passed the ring edge
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

            // Gear icon — top-right corner
            Button {
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(20)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheetView(settings: settings)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            alertManager = AlertManager(settings: settings)
            motion.start()
            UIApplication.shared.isIdleTimerDisabled = true
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
