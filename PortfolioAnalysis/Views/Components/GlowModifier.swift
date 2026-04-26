import SwiftUI

struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let baseRadius: CGFloat
    let intensity: Double
    @State private var pulse: Bool = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity),
                    radius: baseRadius * (pulse ? 1.3 : 0.7))
            .shadow(color: color.opacity(intensity * 0.6),
                    radius: baseRadius * (pulse ? 1.0 : 0.5))
            .shadow(color: color.opacity(intensity * 0.3),
                    radius: baseRadius * (pulse ? 0.7 : 0.3))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.4)
                        .repeatForever(autoreverses: true)
                ) {
                    pulse = true
                }
            }
    }
}

extension View {
    func pulsingGlow(
        color: Color = .green,
        radius: CGFloat = 14,
        intensity: Double = 0.9
    ) -> some View {
        self.modifier(PulsingGlowModifier(
            color: color,
            baseRadius: radius,
            intensity: intensity
        ))
    }
}
