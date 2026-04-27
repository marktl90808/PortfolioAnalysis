//
//  TrendAnalysis.swift
//  PortfolioAnalysis
//
//  Defines the full analysis result for a single stock symbol.
//  This struct is used throughout the app: in views, sorting,
//  and in the analyzer engine.
//

import Foundation

struct TrendAnalysis: Identifiable, Codable {

    // MARK: - Identity
    // SwiftUI uses this for ForEach and lists.
    var id = UUID()

    // MARK: - Core Price Data
    let symbol: String
    let currentPrice: Double
    let yearHighPrice: Double

    // Difference from 52‑week high
    let dollarDifferenceFromYearHigh: Double
    let percentDifferenceFromYearHigh: Double

    // MARK: - Trend Category (your existing enum)
    // Must match your TrendCategory.swift file.
    let trend: TrendCategory

    // MARK: - Slope Metrics
    // These are computed using either Simple Delta or Linear Regression.
    let shortTermSlope: Double
    let mediumTermSlope: Double
    let longTermSlope: Double

    // MARK: - Trend Direction Change
    // improving / worsening / bullishReversal / bearishReversal / flat
    let directionChange: TrendDirectionChange

    // MARK: - Slope Method Used
    // So the UI can show which method was active when this was computed.
    let slopeMethodUsed: SlopeMethod
}
