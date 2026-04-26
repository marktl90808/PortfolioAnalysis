//
//  DefaultTrendAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

struct DefaultTrendAnalyzer: TrendAnalyzer {
    func analyze(symbol: String, currentPrice: Double, yearHigh: Double) -> TrendAnalysis {
        TrendAnalysis(
            symbol: symbol,
            currentPrice: currentPrice,
            yearHighPrice: yearHigh
        )
    }
}
// end of DefaultTrendAnalyzer.swift

