//
//  PortfolioAnalysisResult.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioAnalysisResult: Identifiable, Codable {
    let id = UUID()

    // Core identity
    let symbol: String
    let quantity: Double
    let costBasis: Double

    // Price data
    let currentPrice: Double
    let yearHighPrice: Double
    let dollarDifferenceFromYearHigh: Double
    let percentDifferenceFromYearHigh: Double

    // Trend data
    let trend: TrendCategory
    let shortTermSlope: Double
    let mediumTermSlope: Double
    let longTermSlope: Double
    let directionChange: TrendDirectionChange
    let slopeMethodUsed: SlopeMethod

    let isCash: Bool

    // ⭐ NEW: Classification
    let classification: PositionClassification

    // Computed values
    var totalValue: Double { quantity * currentPrice }
    var gainLoss: Double { totalValue - costBasis }
}

// MARK: - Factory Constructors
extension PortfolioAnalysisResult {

    // MARK: - Cash Position
    static func cash(position: ImportedPosition) -> PortfolioAnalysisResult {

        // Build temporary result
        let temp = PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity,
            costBasis: position.costBasis ?? 0,
            currentPrice: position.price,
            yearHighPrice: position.price,
            dollarDifferenceFromYearHigh: 0,
            percentDifferenceFromYearHigh: 0,
            trend: .unknown,
            shortTermSlope: 0,
            mediumTermSlope: 0,
            longTermSlope: 0,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: true,
            classification: .leaveAlone   // placeholder
        )

        // Classify
        let analyzer = PortfolioAnalyzer()
        let finalClass = analyzer.classify(position: position, result: temp)

        // Build final result
        return PortfolioAnalysisResult(
            symbol: temp.symbol,
            quantity: temp.quantity,
            costBasis: temp.costBasis,
            currentPrice: temp.currentPrice,
            yearHighPrice: temp.yearHighPrice,
            dollarDifferenceFromYearHigh: temp.dollarDifferenceFromYearHigh,
            percentDifferenceFromYearHigh: temp.percentDifferenceFromYearHigh,
            trend: temp.trend,
            shortTermSlope: temp.shortTermSlope,
            mediumTermSlope: temp.mediumTermSlope,
            longTermSlope: temp.longTermSlope,
            directionChange: temp.directionChange,
            slopeMethodUsed: temp.slopeMethodUsed,
            isCash: temp.isCash,
            classification: finalClass
        )
    }

    // MARK: - No Data (fallback)
    static func noData(position: ImportedPosition) -> PortfolioAnalysisResult {

        // Build temporary result
        let temp = PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity,
            costBasis: position.costBasis ?? 0,
            currentPrice: position.price,
            yearHighPrice: position.price,
            dollarDifferenceFromYearHigh: 0,
            percentDifferenceFromYearHigh: 0,
            trend: .unknown,
            shortTermSlope: 0,
            mediumTermSlope: 0,
            longTermSlope: 0,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: false,
            classification: .leaveAlone   // placeholder
        )

        // Classify
        let analyzer = PortfolioAnalyzer()
        let finalClass = analyzer.classify(position: position, result: temp)

        // Build final result
        return PortfolioAnalysisResult(
            symbol: temp.symbol,
            quantity: temp.quantity,
            costBasis: temp.costBasis,
            currentPrice: temp.currentPrice,
            yearHighPrice: temp.yearHighPrice,
            dollarDifferenceFromYearHigh: temp.dollarDifferenceFromYearHigh,
            percentDifferenceFromYearHigh: temp.percentDifferenceFromYearHigh,
            trend: temp.trend,
            shortTermSlope: temp.shortTermSlope,
            mediumTermSlope: temp.mediumTermSlope,
            longTermSlope: temp.longTermSlope,
            directionChange: temp.directionChange,
            slopeMethodUsed: temp.slopeMethodUsed,
            isCash: temp.isCash,
            classification: finalClass
        )
    }

    // MARK: - Full Analysis Constructor
    static func from(position: ImportedPosition,
                     history: [PricePoint],
                     slopeMethod: SlopeMethod) -> PortfolioAnalysisResult {

        let closes = history.map { $0.close }
        let currentPrice = closes.last ?? position.price
        let yearHighPrice = closes.max() ?? currentPrice
        let dollarDifference = currentPrice - yearHighPrice
        let percentDifference = yearHighPrice == 0 ? 0 : (dollarDifference / yearHighPrice) * 100

        let short = computeSlope(prices: history, window: 5, method: slopeMethod)
        let medium = computeSlope(prices: history, window: 20, method: slopeMethod)
        let long = computeSlope(prices: history, window: 60, method: slopeMethod)

        // Build temporary result
        let temp = PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity,
            costBasis: position.costBasis ?? 0,
            currentPrice: currentPrice,
            yearHighPrice: yearHighPrice,
            dollarDifferenceFromYearHigh: dollarDifference,
            percentDifferenceFromYearHigh: percentDifference,
            trend: classifyTrend(short: short, medium: medium, long: long),
            shortTermSlope: short,
            mediumTermSlope: medium,
            longTermSlope: long,
            directionChange: detectDirectionChange(short: short, medium: medium),
            slopeMethodUsed: slopeMethod,
            isCash: false,
            classification: .leaveAlone   // placeholder
        )

        // Classify
        let analyzer = PortfolioAnalyzer()
        let finalClass = analyzer.classify(position: position, result: temp)

        // Build final result
        return PortfolioAnalysisResult(
            symbol: temp.symbol,
            quantity: temp.quantity,
            costBasis: temp.costBasis,
            currentPrice: temp.currentPrice,
            yearHighPrice: temp.yearHighPrice,
            dollarDifferenceFromYearHigh: temp.dollarDifferenceFromYearHigh,
            percentDifferenceFromYearHigh: temp.percentDifferenceFromYearHigh,
            trend: temp.trend,
            shortTermSlope: temp.shortTermSlope,
            mediumTermSlope: temp.mediumTermSlope,
            longTermSlope: temp.longTermSlope,
            directionChange: temp.directionChange,
            slopeMethodUsed: temp.slopeMethodUsed,
            isCash: temp.isCash,
            classification: finalClass
        )
    }

    // MARK: - Slope + Trend Helpers
    private static func computeSlope(prices: [PricePoint], window: Int, method: SlopeMethod) -> Double {
        guard prices.count >= window else { return 0 }

        let slice = Array(prices.suffix(window))
        let closes = slice.map { $0.close }

        switch method {
        case .simpleDelta:
            return (closes.last ?? 0) - (closes.first ?? 0)

        case .linearRegression:
            let n = Double(closes.count)
            let xs = (0..<closes.count).map(Double.init)
            let sumX = xs.reduce(0, +)
            let sumY = closes.reduce(0, +)
            let sumXY = zip(xs, closes).map(*).reduce(0, +)
            let sumX2 = xs.map { $0 * $0 }.reduce(0, +)
            let numerator = (n * sumXY) - (sumX * sumY)
            let denominator = (n * sumX2) - (sumX * sumX)
            return denominator == 0 ? 0 : numerator / denominator
        }
    }

    private static func classifyTrend(short: Double, medium: Double, long: Double) -> TrendCategory {
        if short > 0 && medium > 0 && long > 0 { return .strongUp }
        if short > 0 && medium >= 0 { return .up }
        if abs(short) < 0.01 && abs(medium) < 0.01 { return .flat }
        if short < 0 && medium <= 0 { return .down }
        if short < 0 && medium < 0 && long < 0 { return .strongDown }
        return .unknown
    }

    private static func detectDirectionChange(short: Double, medium: Double) -> TrendDirectionChange {
        if short > 0 && medium < 0 { return .turningUp }
        if short < 0 && medium > 0 { return .turningDown }
        return .none
    }
}
//End of file "PortfolioAnalysisResult.swift"
