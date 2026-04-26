//
//  MarketDataService.swift
//  PortfolioAnalysis
//

import Foundation

protocol MarketDataService: Sendable {
    func fetchQuote(for symbol: String) async throws -> MarketQuote
    func fetchPrices(for symbol: String) async throws -> [PricePoint]

    func cachedPrice(for symbol: String) -> Double?
    func cachedQuote(for symbol: String) -> MarketQuote?   // ← NEW
}

// End of MarketDataService.swift

