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
            let price = priceService.cachedPrice(for: pos.symbol) ?? pos.price
            let value = qty * price

            portfolioTotal += value
            totalCostBasis += pos.costBasis ?? 0
            totalGrowth += value - (pos.costBasis ?? 0)

            if pos.symbol == "CASH" {
                cashTotal += value
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
