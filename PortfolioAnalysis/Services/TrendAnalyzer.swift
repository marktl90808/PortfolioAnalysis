//
//  TrendAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

protocol TrendAnalyzer {
    func analyze(symbol: String, currentPrice: Double, yearHigh: Double) -> TrendAnalysis
}
