//
//  TrendAnalysis.swift
//  PortfolioAnalysis
//

import Foundation

struct TrendAnalysis {
    let symbol: String
    let currentPrice: Double
    let yearHighPrice: Double

    var dollarDifferenceFromYearHigh: Double {
        yearHighPrice - currentPrice
    }
}
