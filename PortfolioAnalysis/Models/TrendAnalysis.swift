//
//  TrendAnalysis.swift
//  PortfolioAnalysis
//
//  Defines the full analysis result for a single stock symbol.
//  This struct is used throughout the app: in views, sorting,
//  and in the analyzer engine.
//

import Foundation

struct TrendAnalysis: Codable {

    // MARK: - Price Metrics
    let currentPrice: Double
    let yearHighPrice: Double
    let dollarDifferenceFromYearHigh: Double
    let percentDifferenceFromYearHigh: Double

    // MARK: - Trend Classification
    let trend: TrendCategory

    // MARK: - Slopes
    let shortTermSlope: Double
    let mediumTermSlope: Double
    let longTermSlope: Double

    // MARK: - Direction Change
    let directionChange: TrendDirectionChange

    // MARK: - Slope Method Used
    let slopeMethodUsed: SlopeMethod
}
//End of TrendAnalysis.swift

