//
//  PositionRowView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct PositionRowView: View {
    let result: PortfolioAnalysisResult

    private var shouldHighlight: Bool {
        result.gainLoss < -500.0 || result.percentDifferenceFromYearHigh <= -10.0
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            // LEFT COLUMN — always 3 lines
            VStack(alignment: .leading, spacing: 4) {
                Text(result.symbol)
                    .font(.subheadline.bold())
                    .lineLimit(1)

                Text("Shares: \(formattedNumber(result.quantity))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("Cost: \(formattedCurrency(result.costBasis))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)



            // RIGHT COLUMN — always 2 lines
            VStack(alignment: .trailing, spacing: 4) {

                Text(formattedCurrency(result.totalValue))
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(String(format: "%.2f%%", result.percentDifferenceFromYearHigh))
                        .font(.caption2)
                        .foregroundColor(result.percentDifferenceFromYearHigh < 0 ? .red : .green)
                        .lineLimit(1)

                    Text("52WH: \(formattedCurrency(result.yearHighPrice))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(shouldHighlight ? Color.red.opacity(0.08) : Color(UIColor.systemBackground))
    }


    // MARK: - Formatters

    private func formattedNumber(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 6
        f.minimumFractionDigits = 0
        f.usesGroupingSeparator = false
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func formattedCurrency(_ value: Double) -> String {
        let absValue = abs(value)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale.current
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 6

        let absString = f.string(from: NSNumber(value: absValue)) ?? "\(absValue)"
        return value < 0 ? "-" + absString : absString
    }
}
