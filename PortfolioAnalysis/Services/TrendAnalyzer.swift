//
//  TrendAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

protocol TrendAnalyzer {
    func analyze(
        symbol: String,
        prices: [PricePoint],
        slopeMethod: SlopeMethod
    ) -> TrendAnalysis
}
