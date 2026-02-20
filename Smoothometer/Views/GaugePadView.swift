import SwiftUI

struct GaugePadView: View {
    let dotOffset: CGSize
    let isBreached: Bool
    @ObservedObject var settings: AppSettings

    // Tracks the ring radius at the moment a pinch gesture begins
    @State private var baseRingRadius: Double = 120.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                // Subtle crosshair reference lines
                CrosshairShape()
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Outer threshold ring
                ThresholdRingView(radius: settings.ringRadius, isBreached: isBreached)

                // Moving bubble dot
                DotView()
                    .offset(dotOffset)
            }
            .contentShape(Rectangle())  // make full area hit-testable for gesture
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let newRadius = (baseRingRadius * scale)
                            .clamped(to: AppSettings.minRingRadius...AppSettings.maxRingRadius)
                        settings.ringRadius = newRadius
                    }
                    .onEnded { _ in
                        // Lock in the new size so the next pinch starts from here
                        baseRingRadius = settings.ringRadius
                    }
            )
            .onAppear {
                baseRingRadius = settings.ringRadius
            }
        }
    }
}

// Simple crosshair: one horizontal line + one vertical line through center
private struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Horizontal
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        // Vertical
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
