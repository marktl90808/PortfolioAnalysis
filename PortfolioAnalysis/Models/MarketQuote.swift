//
//  MarketQuote.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/23/2026.
//

import Foundation

struct MarketQuote: Codable, Sendable {
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
}
// end
// end of MarketQuote.swift
