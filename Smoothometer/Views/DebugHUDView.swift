import SwiftUI

/// Live diagnostic overlay for tuning the physics and breach threshold.
///
/// Toggled by the waveform button in the top toolbar. Shows every value
/// that influences whether the dot hits the ring so you can correlate
/// what you *feel* in the car with the numbers on screen.
///
/// Columns:
///   RAW   — calibrated accelerometer output in G (after tare offset)
///   POS   — normalised dot position from physics sim (−1 … 1)
///   VEL   — current dot velocity in normalised units/sec
///   DIST  — Euclidean distance from centre vs. breach threshold in pts
struct DebugHUDView: View {

    // MARK: - Inputs

    /// Calibrated accelerometer X (lateral, right = positive), in G.
    let calibX: Double

    /// Calibrated accelerometer Y (forward/back, forward = positive), in G.
    let calibY: Double

    /// Physics dot position X, normalised −1 … 1.
    let dotX: Double

    /// Physics dot position Y, normalised −1 … 1.
    let dotY: Double

    /// Physics dot velocity X, normalised units per second.
    let velX: Double

    /// Physics dot velocity Y, normalised units per second.
    let velY: Double

    /// Euclidean distance of the dot from gauge centre, in points.
    let distance: Double

    /// Distance at which breach is triggered, in points.
    let threshold: Double

    /// Whether the dot is currently touching or past the ring.
    let isBreached: Bool

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {

            // Row labels are dimmed; values are full-white for easy scanning.
            dataRow(label: "RAW",
                    x: calibX, xSuffix: "g",
                    y: calibY, ySuffix: "g")

            dataRow(label: "POS",
                    x: dotX, xSuffix: "",
                    y: dotY, ySuffix: "")

            dataRow(label: "VEL",
                    x: velX, xSuffix: "",
                    y: velY, ySuffix: "")

            // Distance row — turns red and shows HIT when breached.
            HStack(spacing: 0) {
                Text("DIST")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f / %.1f pt", distance, threshold))
                    .foregroundStyle(isBreached ? Color.red : Color.white)
                if isBreached {
                    Text("  ● HIT")
                        .foregroundStyle(.red)
                }
            }
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    /// Renders a labelled X/Y pair with sign-forced formatting.
    private func dataRow(
        label: String,
        x: Double, xSuffix: String,
        y: Double, ySuffix: String
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            // %+.3f forces the sign character so columns stay aligned.
            Text(String(format: "X: %+.3f%@   Y: %+.3f%@",
                        x, xSuffix, y, ySuffix))
                .foregroundStyle(.white)
        }
    }
}
