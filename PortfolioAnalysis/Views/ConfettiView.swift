//
//  ConfettiView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/24/2026.
//


import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .pink, .purple]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .animation(.easeOut(duration: particle.duration), value: particle.position)
            }
        }
        .onAppear {
            spawnConfetti()
        }
    }

    private func spawnConfetti() {
        particles = (0..<25).map { _ in
            ConfettiParticle(
                id: UUID(),
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...14),
                position: CGPoint(x: CGFloat.random(in: 0...300),
                                  y: CGFloat.random(in: -20...0)),
                opacity: 1,
                duration: Double.random(in: 1.0...2.0)
            )
        }

        // Animate downward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            for i in particles.indices {
                particles[i].position.y += CGFloat.random(in: 200...350)
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
    let duration: Double
}
