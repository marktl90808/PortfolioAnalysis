//
//  TrendAnalysis.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//

import Foundation

/// Comparison of the latest price to the reported 52-week high.
struct TrendAnalysis: Sendable, CustomStringConvertible {
    /// The stock symbol being analyzed.
    let symbol: String

    /// The latest market price.
    let currentPrice: Double

    /// The reported 52-week high.
    let yearHighPrice: Double

    /// The price gap from current price to the 52-week high.
    /// Positive values mean the current price is above the high.
    let dollarDifferenceFromYearHigh: Double

    /// The price gap from current price to the 52-week high as a percentage of the high.
    let percentDifferenceFromYearHigh: Double

    /// High-level comparison label.
    let trend: TrendClassification

    var description: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2

        let percentFormatter = NumberFormatter()
        percentFormatter.numberStyle = .percent
        percentFormatter.maximumFractionDigits = 2
        percentFormatter.minimumFractionDigits = 2

        let priceText = formatter.string(from: NSNumber(value: currentPrice)) ?? "\(currentPrice)"
        let highText = formatter.string(from: NSNumber(value: yearHighPrice)) ?? "\(yearHighPrice)"
        let gapText = formatter.string(from: NSNumber(value: abs(dollarDifferenceFromYearHigh))) ?? "\(abs(dollarDifferenceFromYearHigh))"
        let gapPercentText = percentFormatter.string(from: NSNumber(value: abs(percentDifferenceFromYearHigh))) ?? "\(abs(percentDifferenceFromYearHigh))%"
        let direction = dollarDifferenceFromYearHigh >= 0 ? "above" : "below"

        return "\(symbol): current \(priceText) vs 52-week high \(highText) — \(gapText) \(direction) high (\(gapPercentText)); \(trend.description)"
    }
}

