import SwiftUI

/// The moving bubble dot at the center of the gauge.
///
/// Rendered as a white-to-yellow radial gradient circle with a yellow glow,
/// mimicking a spirit-level bubble. Its position on screen is controlled by
/// the `.offset()` modifier applied by GaugePadView.
struct DotView: View {

    /// Physical diameter of the dot in SwiftUI points.
    /// 36 pt ≈ 0.5 inches on modern iPhones (~153 pt/inch at 3× scale).
    /// Also used by ContentView to calculate the breach threshold
    /// (dot edge = center offset + radius).
    static let diameter: CGFloat = 36.0

    var body: some View {
        Circle()
            .fill(
                // Radial gradient from bright white at the centre to yellow
                // at the edge, giving the dot a subtle 3-D spherical look.
                RadialGradient(
                    gradient: Gradient(colors: [.white, .yellow]),
                    center: .center,
                    startRadius: 0,
                    endRadius: DotView.diameter / 2
                )
            )
            .frame(width: DotView.diameter, height: DotView.diameter)
            // Soft yellow glow makes the dot easy to spot at a glance while driving.
            .shadow(color: .yellow.opacity(0.85), radius: 10)
    }
}

#Preview {
    DotView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
