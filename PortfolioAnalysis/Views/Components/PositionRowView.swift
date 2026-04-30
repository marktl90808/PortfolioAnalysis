//
//  PositionRowView.swift
//  PortfolioAnalysis
//
//  Row view for a single portfolio analysis result.
//

import SwiftUI

struct PositionRowView: View {
    let result: PortfolioAnalysisResult
    let dayChange: Double

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var shouldHighlight: Bool {
        let isLargeLoss = result.gainLoss < -500.0
        let isBelowHighByMoreThan10 = result.percentDifferenceFromYearHigh <= -10.0
        return isLargeLoss || isBelowHighByMoreThan10
    }

    private var dayChangeColor: Color {
        dayChange < 0 ? .red : (dayChange > 0 ? .green : .secondary)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(result.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Qty: \(formattedQuantity(result.quantity))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text("Cost: \(result.costBasis, format: .currency(code: currencyCode))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 4) {
                Text(result.totalValue, format: .currency(code: currencyCode))
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("Day: \(dayChange, format: .currency(code: currencyCode))")
                    .font(.caption2)
                    .foregroundColor(dayChangeColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    Text(String(format: "%.2f%%", result.percentDifferenceFromYearHigh))
                        .font(.caption2)
                        .foregroundColor(result.percentDifferenceFromYearHigh < 0 ? .red : .green)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 4) {
                        Text("52WH")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(result.yearHighPrice, format: .currency(code: currencyCode))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .fixedSize()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(shouldHighlight ? Color.red.opacity(0.08) : Color(UIColor.systemBackground))
    }

    private func formattedQuantity(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

#if DEBUG
struct PositionRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            PositionRowView(result: sampleResult, dayChange: 42.15)
            PositionRowView(result: sampleResultLoss, dayChange: -128.40)
            PositionRowView(result: sampleResultBelowHigh, dayChange: 0)
        }
        .listStyle(.plain)
        .previewLayout(.sizeThatFits)
    }

    static var sampleResult: PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            symbol: "AAPL",
            quantity: 10,
            costBasis: 1200,
            currentPrice: 150,
            yearHighPrice: 180,
            dollarDifferenceFromYearHigh: -30,
            percentDifferenceFromYearHigh: -16.67,
            trend: .up,
            shortTermSlope: 0,
            mediumTermSlope: 0,
            longTermSlope: 0,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: false
        )
    }

    static var sampleResultLoss: PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            symbol: "LOSS",
            quantity: 100,
            costBasis: 20000,
            currentPrice: 150,
            yearHighPrice: 220,
            dollarDifferenceFromYearHigh: -70,
            percentDifferenceFromYearHigh: -31.82,
            trend: .down,
            shortTermSlope: -1,
            mediumTermSlope: -2,
            longTermSlope: -3,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: false
        )
    }

    static var sampleResultBelowHigh: PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            symbol: "BELOW",
            quantity: 5,
            costBasis: 100,
            currentPrice: 50,
            yearHighPrice: 100,
            dollarDifferenceFromYearHigh: -50,
            percentDifferenceFromYearHigh: -50.0,
            trend: .down,
            shortTermSlope: -0.5,
            mediumTermSlope: -0.8,
            longTermSlope: -1.2,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: false
        )
    }
}
#endif
