//
//  PositionRowView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct PositionRowView: View {
    let result: PortfolioAnalysisResult
    let dayChange: Double

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var highImpactPerShare: Double {
        result.dollarDifferenceFromYearHigh
    }

    private var highImpactTotal: Double {
        highImpactPerShare * result.quantity
    }

    private var highImpactTotalString: String {
        highImpactTotal.formatted(.currency(code: currencyCode))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // LEFT SIDE — Symbol, Badge, Qty, Cost
            VStack(alignment: .leading, spacing: 4) {

                // Symbol
                Text(result.symbol)
                    .font(.headline)

                // Classification Badge
                ClassificationBadgeView(classification: result.classification)

                // Qty
                Text("Qty: \(result.quantity.formatted(.number.precision(.fractionLength(3))))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Cost
                Text("Cost: \(result.costBasis.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // RIGHT SIDE — Current Value, Day Change, 52WH block (fixed)
            VStack(alignment: .trailing, spacing: 6) {

                // Current Value
                Text(result.totalValue, format: .currency(code: currencyCode))
                    .font(.headline)

                // Day Change
                Text("Day: \(dayChange.formatted(.currency(code: currencyCode)))")
                    .font(.caption)
                    .foregroundColor(dayChange < 0 ? .red : .green)

                // ⭐ FIXED: 52WH block — now vertical, no overlap
                VStack(alignment: .trailing, spacing: 2) {

                    // 52WH %
                    Text(String(format: "%.2f%%", result.percentDifferenceFromYearHigh))
                        .font(.caption2)
                        .foregroundColor(result.percentDifferenceFromYearHigh < 0 ? .red : .green)

                    // 52WH price
                    HStack(spacing: 4) {
                        Text("52WH")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(result.yearHighPrice, format: .currency(code: currencyCode))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Total impact (optional but useful)
                    Text(highImpactTotalString)
                        .font(.caption2)
                        .foregroundColor(highImpactTotal < 0 ? .red : .green)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
//End of PositionRowView.swift

