import Foundation

/// Exponential moving average filter.
/// factor = 0.0 → frozen (no update), factor = 1.0 → raw (no filtering)
struct LowPassFilter {
    let factor: Double
    private(set) var value: Double = 0.0

    mutating func apply(input: Double) -> Double {
        value = factor * input + (1.0 - factor) * value
        return value
    }
}
