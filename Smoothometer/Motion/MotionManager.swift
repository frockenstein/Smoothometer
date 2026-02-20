import CoreMotion
import Observation

@Observable
final class MotionManager {
    // Raw filtered values from accelerometer
    private(set) var filteredX: Double = 0.0
    private(set) var filteredY: Double = 0.0

    // Calibration offsets — captured when car is still
    private var calibrationX: Double = 0.0
    private var calibrationY: Double = 0.0

    // Calibration-corrected values — use these for the dot position
    var calibratedX: Double { filteredX - calibrationX }
    var calibratedY: Double { filteredY - calibrationY }

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

    /// Capture current filtered values as the zero point.
    /// Call this when the car is stationary so the dot sits at center.
    func calibrate() {
        calibrationX = filteredX
        calibrationY = filteredY
    }
}
