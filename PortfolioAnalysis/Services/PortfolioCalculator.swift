//
//  PortfolioCalculator.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioCalculator {

    func calculateTotals(
        for positions: [ImportedPosition],
        using priceService: MarketDataService
    ) -> (
        portfolioTotal: Double,
        totalCostBasis: Double,
        totalGrowth: Double,
        cashTotal: Double,
        dayChangeTotal: Double
    ) {

        var portfolioTotal = 0.0
        var totalCostBasis = 0.0
        var totalGrowth = 0.0
        var cashTotal = 0.0
        var dayChangeTotal = 0.0

        for pos in positions {
            let qty = pos.quantity

            // Prefer full quote if available
            let quote = priceService.cachedQuote(for: pos.symbol)
            let price = quote?.price ?? priceService.cachedPrice(for: pos.symbol) ?? pos.price
            let value = qty * price

            // Cash handling
            if pos.isCash {
                cashTotal += value
                portfolioTotal += value
                continue
            }

            // Non-cash positions
            portfolioTotal += value

            let cost = pos.costBasis ?? 0
            totalCostBasis += cost
            totalGrowth += value - cost

            // Daily change
            if let change = quote?.change {
                dayChangeTotal += qty * change
            }
        }

        return (
            portfolioTotal,
            totalCostBasis,
            totalGrowth,
            cashTotal,
            dayChangeTotal
        )
    }
}

