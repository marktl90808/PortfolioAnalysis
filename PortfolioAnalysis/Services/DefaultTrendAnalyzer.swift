//
//  DefaultTrendAnalyzer.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//

import Foundation

/// Default implementation of the TrendAnalyzer protocol.
struct DefaultTrendAnalyzer: TrendAnalyzer {

    func analyze(_ quote: MarketQuote) -> TrendAnalysis {

        // Use current price as a temporary stand-in for 52-week high until available
        let yearHigh = quote.price // TODO: Replace with real 52-week high when available

        // Unified percent-below-high calculation
        let percentBelowHigh: Double = yearHigh > 0
            ? (1 - (quote.price / yearHigh)) * 100
            : 0

        // Dollar gap (negative when below the high)
        let dollarDifferenceFromYearHigh = quote.price - yearHigh

        // Classification based on unified percentBelowHigh
        let classification = classifyTrend(percentBelowHigh: percentBelowHigh)

        return TrendAnalysis(
            symbol: quote.symbol,
            currentPrice: quote.price,
            yearHighPrice: yearHigh,
            dollarDifferenceFromYearHigh: dollarDifferenceFromYearHigh,
            percentDifferenceFromYearHigh: percentBelowHigh,   // <-- unified value
            trend: classification
        )
    }
}

// MARK: - Trend Classification
private extension DefaultTrendAnalyzer {

    func classifyTrend(percentBelowHigh: Double) -> TrendClassification {

        // percentBelowHigh is POSITIVE when below the high
        // Example: 5.3% below high → percentBelowHigh = 5.3

        switch percentBelowHigh {

        case ..<0:
            return .strongGrowth   // above the 52-week high

        case 0..<5:
            return .growth         // near high (0–5%)

        case 5..<15:
            return .flat           // mild pullback (5–15%)

        case 15..<30:
            return .downward       // moderate weakness (15–30%)

        default:
            return .getOut         // significant weakness (30%+)
        }
    }
}
