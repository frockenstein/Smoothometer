import CoreMotion
import Observation

@Observable
final class MotionManager {
    var filteredX: Double = 0.0  // lateral: positive = right
    var filteredY: Double = 0.0  // longitudinal: positive = forward (braking)

    private let motionManager = CMMotionManager()
    private var filterX = LowPassFilter(factor: 0.15)
    private var filterY = LowPassFilter(factor: 0.15)
    private let referenceG: Double = 1.0

    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.filteredX = self.filterX.apply(input: data.acceleration.x / self.referenceG)
            self.filteredY = self.filterY.apply(input: data.acceleration.y / self.referenceG)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}
