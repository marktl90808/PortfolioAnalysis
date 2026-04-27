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
    
    // Computed values
    var totalValue: Double {
        quantity * currentPrice
    }

    var gainLoss: Double {
        totalValue - costBasis
    }
}
