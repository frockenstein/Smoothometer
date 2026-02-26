import SwiftUI

/// Live diagnostic overlay for tuning the physics and breach threshold.
///
/// Toggled by the waveform button in the top toolbar. Shows every value
/// that influences whether the dot hits the ring so you can correlate
/// what you *feel* in the car with the numbers on screen.
struct DebugHUDView: View {

    // MARK: - Inputs

    let calibX: Double       /// Calibrated accelerometer X in G (right = positive)
    let calibY: Double       /// Calibrated accelerometer Y in G (forward = positive)
    let dotX: Double         /// Physics dot position X, normalised −1 … 1
    let dotY: Double         /// Physics dot position Y, normalised −1 … 1
    let velX: Double         /// Physics dot velocity X, normalised units/sec
    let velY: Double         /// Physics dot velocity Y, normalised units/sec
    let distance: Double     /// Euclidean distance from gauge centre, in points
    let threshold: Double    /// Breach trigger distance, in points
    let isBreached: Bool     /// Whether the dot is currently touching the ring

    // MARK: - Derived

    /// 0 … 1 ratio of distance to threshold, clamped so the bar never overflows.
    private var distanceRatio: Double {
        min(distance / max(threshold, 1), 1.0)
    }

    /// Bar fill colour: teal → amber → red as the dot approaches the ring.
    private var barColor: Color {
        switch distanceRatio {
        case ..<0.6:  return Color(red: 0.2, green: 0.85, blue: 0.7)   // teal — clear
        case ..<0.85: return Color(red: 1.0,  green: 0.75, blue: 0.1)  // amber — approaching
        default:      return Color(red: 1.0,  green: 0.25, blue: 0.2)  // red — danger
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ────────────────────────────────────────────────
            HStack(alignment: .center) {
                Text("DIAGNOSTICS")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.38))
                    .kerning(2.5)

                Spacer()

                // Status pill — green OK / red HIT
                HStack(spacing: 5) {
                    Circle()
                        .fill(isBreached ? Color.red : Color(red: 0.2, green: 0.85, blue: 0.5))
                        .frame(width: 6, height: 6)
                        .shadow(color: isBreached ? .red : .green, radius: 3)
                    Text(isBreached ? "HIT" : "OK")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(isBreached ? Color.red : Color(red: 0.2, green: 0.85, blue: 0.5))
                        .kerning(1.5)
                }
            }

            hairline.padding(.top, 10).padding(.bottom, 10)

            // ── Data rows ─────────────────────────────────────────────
            dataRow(label: "RAW", x: calibX, y: calibY, suffix: "g",
                    valueColor: .white)
            dataRow(label: "POS", x: dotX,   y: dotY,   suffix: "",
                    valueColor: .white)
                .padding(.top, 7)
            dataRow(label: "VEL", x: velX,   y: velY,   suffix: "",
                    valueColor: Color(white: 0.55))
                .padding(.top, 7)

            hairline.padding(.top, 10).padding(.bottom, 10)

            // ── Distance progress bar ──────────────────────────────────
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 0) {
                    Text("DIST")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(white: 0.38))
                        .kerning(1)
                    Spacer()
                    Text(String(format: "%.1f / %.0f pt", distance, threshold))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(barColor)
                }

                // Track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.12))
                            .frame(height: 5)

                        // Filled portion
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [barColor.opacity(0.7), barColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * distanceRatio, height: 5)
                            .animation(.linear(duration: 0.05), value: distanceRatio)
                    }
                }
                .frame(height: 5)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.04, green: 0.04, blue: 0.08).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(white: 0.18), lineWidth: 0.5)
        )
    }

    // MARK: - Helpers

    /// One horizontal rule used as a section divider.
    private var hairline: some View {
        Rectangle()
            .fill(Color(white: 0.15))
            .frame(height: 0.5)
    }

    /// A labelled X / Y pair in monospaced type.
    /// `%+.3f` forces the sign character so all columns stay aligned.
    private func dataRow(
        label: String,
        x: Double, y: Double,
        suffix: String,
        valueColor: Color
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(white: 0.38))
                .kerning(1)
                .frame(width: 34, alignment: .leading)

            Spacer()

            Text(String(format: "X  %+.3f%@", x, suffix))
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(valueColor)

            Text("   ")   // fixed gap keeps Y column pinned

            Text(String(format: "Y  %+.3f%@", y, suffix))
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }
}
