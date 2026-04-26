//
//  PortfolioCalculator.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioTotals: Sendable {
    let portfolioTotal: Double
    let totalCostBasis: Double
    let totalGrowth: Double
    let cashTotal: Double
    let dayChangeTotal: Double
}

struct PortfolioCalculator {
    func calculateTotals(for positions: [ImportedPosition], using priceService: DefaultMarketDataService) -> PortfolioTotals {
        var marketValue: Double = 0
        var costBasis: Double = 0
        var cash: Double = 0
        var dayChange: Double = 0

        for p in positions {
            if p.isCash {
                cash += p.cashValue ?? 0
                continue
            }
            let qty = p.quantity ?? 0
            let price = priceService.cachedPrice(for: p.ticker) ?? 0
            marketValue += qty * price
            costBasis += qty * (p.costBasisPerShare ?? 0)
            dayChange += p.dayChangeAmount ?? 0
        }

        let total = marketValue + cash
        let growth = total - costBasis

        return PortfolioTotals(
            portfolioTotal: total,
            totalCostBasis: costBasis,
            totalGrowth: growth,
            cashTotal: cash,
            dayChangeTotal: dayChange
        )
    }
}
