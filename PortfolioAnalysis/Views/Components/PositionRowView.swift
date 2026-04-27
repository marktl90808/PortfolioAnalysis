//
//  PositionRowView.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/26/2026.
//

import SwiftUI

struct PositionRowView: View {
    let result: PortfolioAnalysisResult

    private var currentValue: Double {
        result.currentPrice * Double(result.quantity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            if result.isCash {
                // MARK: - CASH ROW
                HStack {
                    Text("Cash")
                        .font(.headline)

                    Spacer()

                    Text(result.costBasis, format: .currency(code: "USD"))
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            } else {
                // MARK: - STOCK ROW
                HStack(spacing: 8) {
                    Text(result.symbol)
                        .font(.headline)

                    Text(result.currentPrice, format: .currency(code: "USD"))
                        .font(.subheadline)

                    Spacer()

                    HStack(spacing: 4) {
                        Text(arrowSymbol)
                            .foregroundColor(arrowColor)
                            .font(.footnote.bold())

                        Text(currentValue, format: .currency(code: "USD"))
                            .font(.footnote.bold())
                            .foregroundColor(arrowColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }

                HStack(spacing: 8) {
                    Text("52‑wk High: \(result.yearHighPrice, format: .currency(code: "USD"))")
                        .font(.caption)

                    Text("Δ \(result.dollarDifferenceFromYearHigh, format: .currency(code: "USD"))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if abs(result.percentDifferenceFromYearHigh) <= 2 {
                    Text("🎉 Near 52‑week high! Great performance!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .developerLabel("PositionRowView")
    }

    // MARK: - Arrow Logic (Stocks Only)
    private var arrowSymbol: String {
        let basis = result.costBasis
        let value = result.currentPrice * Double(result.quantity)

        if basis == 0 { return "—" }
        if value > basis { return "▲" }
        if value < basis { return "▼" }
        return "—"
    }

    private var arrowColor: Color {
        let basis = result.costBasis
        let value = result.currentPrice * Double(result.quantity)

        if basis == 0 { return .secondary }
        if value > basis { return .green }
        if value < basis { return .red }
        return .secondary
    }
}
