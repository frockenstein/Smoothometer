import SwiftUI

struct ContentView: View {
    @State private var motion = MotionManager()
    @State private var settings = AppSettings()
    @State private var isSettingsPresented = false
    @State private var isBreached = false
    @State private var alertManager: AlertManager?

    private var maxDotTravel: Double {
        settings.ringRadius - DotView.diameter / 2
    }

    private var dotOffset: CGSize {
        let x = motion.filteredX.clamped(to: -2.0...2.0)
        let y = motion.filteredY.clamped(to: -2.0...2.0)
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
