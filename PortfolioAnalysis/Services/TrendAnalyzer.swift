//
//  TrendAnalyzer.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//

import Foundation

protocol TrendAnalyzer: Sendable {
    func analyze(_ quote: MarketQuote) -> TrendAnalysis
}
