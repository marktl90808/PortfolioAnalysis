//
//  PortfolioAnalysisResult.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/23/2026.
//

import Foundation

/// Combines an imported position with its computed market analysis.
struct PortfolioAnalysisResult: Sendable {
    let position: ImportedPosition
    let analysis: TrendAnalysis
    let previousClosePrice: Double?

    var quantity: Double? {
        position.quantity
    }

    var totalValue: Double? {
        guard let quantity else { return nil }
        return quantity * analysis.currentPrice
    }

    var dailyGrowthValue: Double? {
        guard let quantity,
              let previousClosePrice else { return nil }

        return quantity * (analysis.currentPrice - previousClosePrice)
    }
}
