//
//  DebugOverlay.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/7/2026.
//


import SwiftUI

struct DebugOverlay: View {
    let positions: [ImportedPosition]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG RAW VALUES")
                .font(.caption.bold())
                .foregroundColor(.red)

            ForEach(positions) { pos in
                Text("• \(pos.symbol) — \(pos.name)")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.2))
        .cornerRadius(8)
        .padding()
    }
}
