import SwiftUI

/// The circular threshold ring surrounding the dot.
///
/// Normally drawn as a semi-transparent white stroke. When the dot's edge
/// reaches or crosses this ring (a "breach"), it snaps to red to give the
/// driver an instant visual cue alongside the audio/haptic alert.
///
/// The ring radius is user-adjustable via the settings slider and pinch gesture.
struct ThresholdRingView: View {

    /// Radius of the ring in SwiftUI points. Diameter = radius × 2.
    let radius: Double

    /// When true the ring turns red and thickens slightly to signal a breach.
    let isBreached: Bool

    var body: some View {
        Circle()
            .stroke(
                // Red on breach, faint white at rest.
                isBreached ? Color.red : Color.white.opacity(0.55),
                // Slightly thicker stroke on breach for extra visibility.
                lineWidth: isBreached ? 3.0 : 2.0
            )
            .frame(width: radius * 2, height: radius * 2)
            // Fast ease-out so the colour change feels snappy, not laggy.
            .animation(.easeOut(duration: 0.1), value: isBreached)
    }
}

#Preview {
    VStack(spacing: 40) {
        ThresholdRingView(radius: 100, isBreached: false)
        ThresholdRingView(radius: 100, isBreached: true)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
