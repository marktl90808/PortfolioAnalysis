//
//  DefaultTrendAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

final class DefaultTrendAnalyzer: TrendAnalyzer {

    func analyze(
        symbol: String,
        prices: [PricePoint],
        slopeMethod: SlopeMethod
    ) -> TrendAnalysis {

        let currentPrice = prices.last?.close ?? 0
        let yearHigh = prices.map { $0.close }.max() ?? currentPrice

        let dollarDiff = yearHigh - currentPrice
        let percentDiff = yearHigh > 0 ? (dollarDiff / yearHigh) * 100 : 0

        let shortSlope = slope(for: prices, method: slopeMethod, window: 5)
        let mediumSlope = slope(for: prices, method: slopeMethod, window: 20)
        let longSlope = slope(for: prices, method: slopeMethod, window: 60)

        let trendCategory = classifyTrend(
            currentPrice: currentPrice,
            yearHigh: yearHigh,
            short: shortSlope,
            medium: mediumSlope,
            long: longSlope
        )

        let directionChange = classifyDirectionChange(
            short: shortSlope,
            medium: mediumSlope,
            long: longSlope
        )

        return TrendAnalysis(
            symbol: symbol,
            currentPrice: currentPrice,
            yearHighPrice: yearHigh,
            dollarDifferenceFromYearHigh: dollarDiff,
            percentDifferenceFromYearHigh: percentDiff,
            trend: trendCategory,
            shortTermSlope: shortSlope,
            mediumTermSlope: mediumSlope,
            longTermSlope: longSlope,
            directionChange: directionChange,
            slopeMethodUsed: slopeMethod
        )
    }

    // MARK: - Slope Calculation

    private func slope(
        for prices: [PricePoint],
        method: SlopeMethod,
        window: Int
    ) -> Double {
        guard prices.count > 1 else { return 0 }

        switch method {
        case .simpleDelta:
            return simpleDeltaSlope(prices, days: window)

        case .linearRegression:
            let slice = Array(prices.suffix(window))
            return regressionSlope(slice)
        }
    }

    private func simpleDeltaSlope(_ prices: [PricePoint], days: Int) -> Double {
        guard prices.count > days else { return 0 }
        let recent = prices[prices.count - 1].close
        let past = prices[prices.count - days - 1].close
        return recent - past
    }

    private func regressionSlope(_ prices: [PricePoint]) -> Double {
        guard prices.count > 1 else { return 0 }

        let n = Double(prices.count)
        let xs = prices.indices.map { Double($0) }
        let ys = prices.map { $0.close }

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)

        let numerator = (n * sumXY) - (sumX * sumY)
        let denominator = (n * sumX2) - (sumX * sumX)

        return denominator != 0 ? numerator / denominator : 0
    }

    // MARK: - Trend Category (placeholder or your existing logic)

    private func classifyTrend(
        currentPrice: Double,
        yearHigh: Double,
        short: Double,
        medium: Double,
        long: Double
    ) -> TrendCategory {
        // Replace with your existing logic if needed
        if short > 0 && medium > 0 && long > 0 {
            return .growth
        } else if short < 0 && medium < 0 && long < 0 {
            return .downward
        } else {
            return .flat
        }
    }

    // MARK: - Direction Change

    private func classifyDirectionChange(
        short: Double,
        medium: Double,
        long: Double
    ) -> TrendDirectionChange {

        if short > medium && medium > long {
            return .improving
        }

        if short < medium && medium < long {
            return .worsening
        }

        if long < 0 && short > 0 {
            return .bullishReversal
        }

        if long > 0 && short < 0 {
            return .bearishReversal
        }

        return .flat
    }
}
