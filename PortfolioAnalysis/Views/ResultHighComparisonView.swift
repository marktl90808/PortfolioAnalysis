//
//  ResultHighComparisonView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/24/2026.
//

import SwiftUI

struct ResultHighComparisonView: View {
    let current: Double
    let high: Double

    @State private var showConfetti = false

    // Unified percent-below-high calculation
    var percentBelow: Double {
        high > 0 ? (1 - current / high) * 100 : 0
    }

    // Celebration triggers:
    // - At or above the 52-week high
    // - Within 2% of the high
    var isCelebration: Bool {
        current >= high || percentBelow < 2
    }

    var body: some View {
        ZStack(alignment: .topLeading) {

            contentBox

            if showConfetti {
                ConfettiView()
                    .frame(height: 120)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Main content box with optional glow

    private var contentBox: some View {
        let base = VStack(alignment: .leading, spacing: 4) {
            if isCelebration {
                Text("🎉 The stock is reaching new highs! Celebrate!")
                    .font(.caption)
                    .foregroundColor(Color.green)
                    .onAppear { showConfetti = true }
            } else {
                Text(comparisonMessage)
                    .font(.caption)
                    .foregroundColor(colorForPercent)
            }
        }
        .padding(6)
        .background(Color(.systemBackground))
        .cornerRadius(8)

        if isCelebration {
            return AnyView(
                base.pulsingGlow(color: Color.green, radius: 16, intensity: 0.9)
            )
        } else {
            return AnyView(base)
        }
    }

    // MARK: - Comparison Message

    private var comparisonMessage: String {
        let formatted = percentBelow.formatted(.number.precision(.fractionLength(1)))

        switch percentBelow {
        case 0..<5:
            return "Near 52‑week high (\(formatted)%)"
        case 5..<15:
            return "Mild pullback (\(formatted)%)"
        case 15..<30:
            return "Moderate weakness (\(formatted)%)"
        default:
            return "Significant weakness (\(formatted)%)"
        }
    }

    // MARK: - Color Tier

    private var colorForPercent: Color {
        switch percentBelow {
        case 0..<5: return .green
        case 5..<15: return .yellow
        case 15..<30: return .orange
        default: return .red
        }
    }
}
