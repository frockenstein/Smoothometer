import SwiftUI

struct ThresholdRingView: View {
    let radius: Double
    let isBreached: Bool

    var body: some View {
        Circle()
            .stroke(
                isBreached ? Color.red : Color.white.opacity(0.55),
                lineWidth: isBreached ? 3.0 : 2.0
            )
            .frame(width: radius * 2, height: radius * 2)
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
