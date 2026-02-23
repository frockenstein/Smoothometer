import SwiftUI

/// The main full-screen gauge canvas.
///
/// Layers (bottom to top):
///   1. Black background
///   2. Faint crosshair lines — reference for finding dead-centre
///   3. ThresholdRingView — the user-adjustable alert boundary
///   4. DotView — the G-force bubble, offset by the calibrated accelerometer
///
/// Also owns the pinch-to-resize gesture that lets the driver adjust the
/// threshold ring size without opening settings.
struct GaugePadView: View {

    /// Pre-computed dot offset in points, passed in from ContentView.
    /// Positive X = right, negative Y = up (SwiftUI's Y axis is inverted).
    let dotOffset: CGSize

    /// Whether the dot is currently touching or outside the threshold ring.
    /// Forwarded to ThresholdRingView to drive its breach colour.
    let isBreached: Bool

    /// Shared settings — read for ring radius, written during pinch gesture.
    /// No property wrapper needed because AppSettings uses @Observable.
    var settings: AppSettings

    /// Ring radius at the moment the current pinch gesture began.
    /// Pinch scale is multiplicative from this baseline, which prevents
    /// a jump when starting a second pinch after the first has ended.
    @State private var baseRingRadius: Double = 120.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen dark background.
                Color.black.ignoresSafeArea()

                // Very faint crosshair helps the driver find true centre
                // without distracting from the dot during driving.
                CrosshairShape()
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // The alert threshold ring. Turns red when dot breaches it.
                ThresholdRingView(radius: settings.ringRadius, isBreached: isBreached)

                // The G-force bubble. Offset is applied from the ZStack's centre.
                DotView()
                    .offset(dotOffset)
            }
            // Make the full canvas hit-testable so the pinch gesture works
            // even in areas not covered by child views.
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        // Multiply the pre-pinch baseline by the live scale factor,
                        // then clamp to the allowed ring size range.
                        let newRadius = (baseRingRadius * scale)
                            .clamped(to: AppSettings.minRingRadius...AppSettings.maxRingRadius)
                        settings.ringRadius = newRadius
                    }
                    .onEnded { _ in
                        // Lock in the settled radius so the next pinch starts correctly.
                        baseRingRadius = settings.ringRadius
                    }
            )
            .onAppear {
                // Sync the baseline with whatever is currently persisted,
                // so the first pinch doesn't jump from the default 120.
                baseRingRadius = settings.ringRadius
            }
        }
    }
}

// MARK: - Supporting shapes

/// Draws a simple horizontal + vertical crosshair through the centre of its frame.
private struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Horizontal line across full width at mid-height.
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        // Vertical line across full height at mid-width.
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Utility

extension Comparable {
    /// Clamp a value so it never falls outside the given closed range.
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
