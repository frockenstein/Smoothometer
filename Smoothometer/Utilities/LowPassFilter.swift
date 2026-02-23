import Foundation

/// Exponential moving average (EMA) low-pass filter.
///
/// Smooths a noisy signal by blending each new input with the previous
/// output. Higher `factor` values let more of the raw signal through
/// (less smoothing); lower values produce a smoother but slower response.
///
/// - factor = 0.0 → output never changes (frozen)
/// - factor = 1.0 → output equals raw input (no filtering)
/// - factor = 0.15 at 60 Hz → ~100ms time constant, good for accelerometer data
struct LowPassFilter {

    /// Blend weight for the incoming sample. Range: 0.0–1.0.
    let factor: Double

    /// The current filtered output value.
    private(set) var value: Double = 0.0

    /// Feed a new raw sample into the filter and return the smoothed output.
    /// Formula: value = factor × input + (1 − factor) × previousValue
    mutating func apply(input: Double) -> Double {
        value = factor * input + (1.0 - factor) * value
        return value
    }
}
