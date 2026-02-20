import SwiftUI

struct DotView: View {
    // ~0.5 inches: 36pt renders at approximately 0.5in on modern iPhones (460ppi ÷ ~3x scale ≈ 153pt/in)
    static let diameter: CGFloat = 36.0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [.white, .yellow]),
                    center: .center,
                    startRadius: 0,
                    endRadius: DotView.diameter / 2
                )
            )
            .frame(width: DotView.diameter, height: DotView.diameter)
            .shadow(color: .yellow.opacity(0.85), radius: 10)
    }
}

#Preview {
    DotView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
