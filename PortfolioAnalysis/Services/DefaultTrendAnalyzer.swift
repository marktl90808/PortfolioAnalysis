//
//  DefaultTrendAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

final class DefaultTrendAnalyzer {

    // MARK: - Public Entry Point
    func analyze(symbol: String, prices: [PricePoint], slopeMethod: SlopeMethod) -> TrendAnalysis {

        guard let latest = prices.last else {
            return TrendAnalysis(
                currentPrice: 0,
                yearHighPrice: 0,
                dollarDifferenceFromYearHigh: 0,
                percentDifferenceFromYearHigh: 0,
                trend: .unknown,
                shortTermSlope: 0,
                mediumTermSlope: 0,
                longTermSlope: 0,
                directionChange: .none,
                slopeMethodUsed: slopeMethod
            )
        }

        let currentPrice = latest.close
        let yearHighPrice = prices.map { $0.close }.max() ?? currentPrice
        let dollarDiff = currentPrice - yearHighPrice
        let percentDiff = (dollarDiff / yearHighPrice) * 100

        // Compute slopes
        let shortSlope = computeSlope(prices: prices, window: 5, method: slopeMethod)
        let mediumSlope = computeSlope(prices: prices, window: 20, method: slopeMethod)
        let longSlope = computeSlope(prices: prices, window: 60, method: slopeMethod)

        let trendCategory = classifyTrend(
            short: shortSlope,
            medium: mediumSlope,
            long: longSlope
        )

        let directionChange = detectDirectionChange(
            short: shortSlope,
            medium: mediumSlope
        )

        return TrendAnalysis(
            currentPrice: currentPrice,
            yearHighPrice: yearHighPrice,
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
    private func computeSlope(prices: [PricePoint], window: Int, method: SlopeMethod) -> Double {
        guard prices.count >= window else { return 0 }

        let slice = Array(prices.suffix(window))
        let closes = slice.map { $0.close }

        switch method {
        case .simpleDelta:
            return closes.last! - closes.first!

        case .linearRegression:
            return linearRegressionSlope(values: closes)
        }
    }

    // MARK: - Linear Regression Slope
    private func linearRegressionSlope(values: [Double]) -> Double {
        let n = Double(values.count)
        let xs = (0..<values.count).map { Double($0) }
        let ys = values

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).map(*).reduce(0, +)
        let sumX2 = xs.map { $0 * $0 }.reduce(0, +)

        let numerator = (n * sumXY) - (sumX * sumY)
        let denominator = (n * sumX2) - (sumX * sumX)

        return denominator == 0 ? 0 : numerator / denominator
    }

    // MARK: - Trend Classification
    private func classifyTrend(short: Double, medium: Double, long: Double) -> TrendCategory {

        // Strong Uptrend
        if short > 0 && medium > 0 && long > 0 {
            return .strongUp
        }

        // Mild Uptrend
        if short > 0 && medium >= 0 {
            return .up
        }

        // Flat
        if abs(short) < 0.01 && abs(medium) < 0.01 {
            return .flat
        }

        // Mild Downtrend
        if short < 0 && medium <= 0 {
            return .down
        }

        // Strong Downtrend
        if short < 0 && medium < 0 && long < 0 {
            return .strongDown
        }

        return .unknown
    }

    // MARK: - Direction Change Detection
    private func detectDirectionChange(short: Double, medium: Double) -> TrendDirectionChange {
        if short > 0 && medium < 0 {
            return .turningUp
        }
        if short < 0 && medium > 0 {
            return .turningDown
        }
        return .none
    }
}
//End of DefaultTrendAnalyzer.swift

