import CoreMotion
import Combine

final class MotionManager: ObservableObject {
    @Published var filteredX: Double = 0.0  // lateral: positive = right
    @Published var filteredY: Double = 0.0  // longitudinal: positive = forward (braking)

    private let motionManager = CMMotionManager()
    private var filterX = LowPassFilter(factor: 0.15)
    private var filterY = LowPassFilter(factor: 0.15)

    // Reference scale: 1.0g maps to full-scale travel on the gauge.
    // Hard street driving rarely exceeds 0.4g; track use can reach 1.0g+.
    private let referenceG: Double = 1.0

    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            // Phone mounted portrait, screen facing driver.
            // X axis: lateral (positive = passenger side of car)
            // Y axis: longitudinal (positive = forward; spikes on braking due to inertia)
            self.filteredX = self.filterX.apply(input: data.acceleration.x / self.referenceG)
            self.filteredY = self.filterY.apply(input: data.acceleration.y / self.referenceG)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
