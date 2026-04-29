//
//  PortfolioAnalysisResult.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioAnalysisResult: Identifiable, Codable {
    let id: UUID

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
    
    // Computed values
    var totalValue: Double {
        quantity * currentPrice
    }

    var gainLoss: Double {
        totalValue - costBasis
    }

    // MARK: - Designated initializer
    init(
        id: UUID = UUID(),
        symbol: String,
        quantity: Double,
        costBasis: Double,
        currentPrice: Double,
        yearHighPrice: Double,
        dollarDifferenceFromYearHigh: Double,
        percentDifferenceFromYearHigh: Double,
        trend: TrendCategory,
        shortTermSlope: Double,
        mediumTermSlope: Double,
        longTermSlope: Double,
        directionChange: TrendDirectionChange,
        slopeMethodUsed: SlopeMethod,
        isCash: Bool
    ) {
        self.id = id
        self.symbol = symbol
        self.quantity = quantity
        self.costBasis = costBasis
        self.currentPrice = currentPrice
        self.yearHighPrice = yearHighPrice
        self.dollarDifferenceFromYearHigh = dollarDifferenceFromYearHigh
        self.percentDifferenceFromYearHigh = percentDifferenceFromYearHigh
        self.trend = trend
        self.shortTermSlope = shortTermSlope
        self.mediumTermSlope = mediumTermSlope
        self.longTermSlope = longTermSlope
        self.directionChange = directionChange
        self.slopeMethodUsed = slopeMethodUsed
        self.isCash = isCash
    }
}

// MARK: - Special Constructors
extension PortfolioAnalysisResult {

    static func cash(position: ImportedPosition) -> PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity ?? 0,
            costBasis: position.costBasis ?? 0,
            currentPrice: 1,
            yearHighPrice: 1,
            dollarDifferenceFromYearHigh: 0,
            percentDifferenceFromYearHigh: 0,
            trend: .flat,
            shortTermSlope: 0,
            mediumTermSlope: 0,
            longTermSlope: 0,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: true
        )
    }

    static func noData(position: ImportedPosition) -> PortfolioAnalysisResult {
        PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity ?? 0,
            costBasis: position.costBasis ?? 0,
            currentPrice: 0,
            yearHighPrice: 0,
            dollarDifferenceFromYearHigh: 0,
            percentDifferenceFromYearHigh: 0,
            trend: .flat,
            shortTermSlope: 0,
            mediumTermSlope: 0,
            longTermSlope: 0,
            directionChange: .none,
            slopeMethodUsed: .simpleDelta,
            isCash: position.isCash
        )
    }

    static func from(position: ImportedPosition, history: [PricePoint]) -> PortfolioAnalysisResult {
        let analyzer = DefaultTrendAnalyzer()

        let analysis = analyzer.analyze(
            symbol: position.symbol,
            prices: history,
            slopeMethod: .simpleDelta
        )

        return PortfolioAnalysisResult(
            symbol: position.symbol,
            quantity: position.quantity ?? 0,
            costBasis: position.costBasis ?? 0,
            currentPrice: analysis.currentPrice,
            yearHighPrice: analysis.yearHighPrice,
            dollarDifferenceFromYearHigh: analysis.dollarDifferenceFromYearHigh,
            percentDifferenceFromYearHigh: analysis.percentDifferenceFromYearHigh,
            trend: analysis.trend,
            shortTermSlope: analysis.shortTermSlope,
            mediumTermSlope: analysis.mediumTermSlope,
            longTermSlope: analysis.longTermSlope,
            directionChange: analysis.directionChange,
            slopeMethodUsed: analysis.slopeMethodUsed,
            isCash: false
        )
    }
}
