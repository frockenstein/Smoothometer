import SwiftUI

/// The moving bubble dot at the center of the gauge.
///
/// Color shifts along a four-stop gradient as the dot approaches the ring:
///   pale grey-green  →  yellow  →  orange  →  red
///
/// The glow shadow follows the same colour so the whole dot "heats up"
/// visually as G forces build. Position is controlled by the `.offset()`
/// applied in GaugePadView.
struct DotView: View {

    /// Physical diameter of the dot in SwiftUI points.
    /// 36 pt ≈ 0.5 inches on modern iPhones (~153 pt/inch at 3× scale).
    /// Also used by ContentView to calculate the breach threshold
    /// (dot edge = center offset + radius).
    static let diameter: CGFloat = 36.0

    /// 0.0 = dot is at rest in the centre; 1.0 = dot is touching the ring.
    /// Drives the colour and glow of the dot.
    let proximity: Double

    // MARK: - Body

    var body: some View {
        let color = proximityColor(proximity)

        Circle()
            .fill(
                // Radial gradient: bright white highlight at centre fades to
                // the proximity colour at the edge — gives a 3-D sphere feel.
                RadialGradient(
                    gradient: Gradient(colors: [.white, color]),
                    center: .center,
                    startRadius: 0,
                    endRadius: DotView.diameter / 2
                )
            )
            .frame(width: DotView.diameter, height: DotView.diameter)
            // Glow matches the body colour so the dot "heats up" as it nears the ring.
            .shadow(color: color.opacity(0.9), radius: 12)
    }

    // MARK: - Colour interpolation

    /// Returns an interpolated colour along the four-stop ramp:
    ///
    ///   0.00 → 0.55   pale grey-green (resting, calm)
    ///   0.55 → 0.80   yellow          (approaching)
    ///   0.80 → 1.00   orange → red    (imminent / breached)
    ///
    /// Linear interpolation between adjacent stops keeps the transition smooth
    /// at 60 Hz without needing an explicit SwiftUI animation.
    private func proximityColor(_ t: Double) -> Color {
        struct Stop { let t, r, g, b: Double }

        let stops: [Stop] = [
            Stop(t: 0.00, r: 0.70, g: 0.84, b: 0.76),   // pale grey-green
            Stop(t: 0.55, r: 1.00, g: 0.90, b: 0.10),   // yellow
            Stop(t: 0.80, r: 1.00, g: 0.50, b: 0.05),   // orange
            Stop(t: 1.00, r: 1.00, g: 0.18, b: 0.12),   // red
        ]

        let clamped = max(0.0, min(1.0, t))

        for i in 0 ..< stops.count - 1 {
            let lo = stops[i], hi = stops[i + 1]
            guard clamped <= hi.t else { continue }
            let span = hi.t - lo.t
            let f    = span > 0 ? (clamped - lo.t) / span : 0
            return Color(
                red:   lo.r + (hi.r - lo.r) * f,
                green: lo.g + (hi.g - lo.g) * f,
                blue:  lo.b + (hi.b - lo.b) * f
            )
        }
        return Color(red: stops.last!.r, green: stops.last!.g, blue: stops.last!.b)
    }
}

#Preview {
    HStack(spacing: 20) {
        DotView(proximity: 0.0)
        DotView(proximity: 0.5)
        DotView(proximity: 0.8)
        DotView(proximity: 1.0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
