import SwiftUI

struct GaugePadView: View {
    let dotOffset: CGSize
    let isBreached: Bool
    var settings: AppSettings  // @Observable — no wrapper needed for observation

    @State private var baseRingRadius: Double = 120.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                CrosshairShape()
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                ThresholdRingView(radius: settings.ringRadius, isBreached: isBreached)

                DotView()
                    .offset(dotOffset)
            }
            .contentShape(Rectangle())
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let newRadius = (baseRingRadius * scale)
                            .clamped(to: AppSettings.minRingRadius...AppSettings.maxRingRadius)
                        settings.ringRadius = newRadius
                    }
                    .onEnded { _ in
                        baseRingRadius = settings.ringRadius
                    }
            )
            .onAppear {
                baseRingRadius = settings.ringRadius
            }
        }
    }
}

private struct CrosshairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
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
