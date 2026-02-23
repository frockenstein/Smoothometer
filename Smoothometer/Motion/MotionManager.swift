import CoreMotion
import Observation

/// Reads raw accelerometer data from the device and exposes smoothed,
/// calibration-corrected G-force values for use by the gauge.
///
/// Coordinate system (phone mounted portrait, screen facing driver):
///   X axis → lateral force  (positive = toward passenger side)
///   Y axis → longitudinal   (positive = forward / braking spike)
///   Z axis → through screen (mostly gravity when mounted vertically — ignored here)
@Observable
final class MotionManager {

    // MARK: - Published motion values

    /// Smoothed lateral accelerometer reading in g-units, before calibration offset.
    private(set) var filteredX: Double = 0.0

    /// Smoothed longitudinal accelerometer reading in g-units, before calibration offset.
    private(set) var filteredY: Double = 0.0

    // MARK: - Calibration

    /// Lateral offset captured at rest. Subtracted from filteredX to zero the dot.
    private var calibrationX: Double = 0.0

    /// Longitudinal offset captured at rest. Subtracted from filteredY to zero the dot.
    private var calibrationY: Double = 0.0

    /// Lateral G-force with the resting offset removed.
    /// This is the value used to position the dot horizontally.
    var calibratedX: Double { filteredX - calibrationX }

    /// Longitudinal G-force with the resting offset removed.
    /// This is the value used to position the dot vertically.
    var calibratedY: Double { filteredY - calibrationY }

    // MARK: - Private

    /// Underlying CoreMotion accelerometer manager. Apple recommends one instance per app.
    private let motionManager = CMMotionManager()

    /// Independent low-pass filters for each axis to smooth out sensor jitter.
    private var filterX = LowPassFilter(factor: 0.15)
    private var filterY = LowPassFilter(factor: 0.15)

    /// Divisor used to normalise raw accelerometer values into g-units.
    /// 1.0g of force = full-scale on the gauge (dot reaches the ring edge).
    private let referenceG: Double = 1.0

    // MARK: - Public interface

    /// True if the device has an accelerometer (always true on iPhone).
    var isAvailable: Bool { motionManager.isAccelerometerAvailable }

    /// Begin streaming accelerometer updates at 60 Hz on the main queue.
    /// Each sample is filtered and stored in filteredX / filteredY.
    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            // Divide by referenceG to express the reading in g-units,
            // then feed through the low-pass filter to remove jitter.
            self.filteredX = self.filterX.apply(input: data.acceleration.x / self.referenceG)
            self.filteredY = self.filterY.apply(input: data.acceleration.y / self.referenceG)
        }
    }

    /// Stop accelerometer updates. Called when the view disappears to save battery.
    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

    /// Snapshot the current filtered values as the zero/rest baseline.
    /// After calibration, calibratedX and calibratedY will read 0.0 when
    /// the phone is in the same orientation as when this was called.
    /// Should be called ~2 seconds after start() so the filter has settled.
    func calibrate() {
        calibrationX = filteredX
        calibrationY = filteredY
    }
}
