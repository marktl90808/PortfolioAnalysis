//
//  PortfolioAnalysisResult.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioAnalysisResult: Identifiable {
    let id = UUID()

    let position: ImportedPosition
    let analysis: TrendAnalysis
    let quantity: Double?
    let totalValue: Double?
}
