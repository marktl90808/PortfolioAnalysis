//
//  PortfolioAnalyzer.swift
//  PortfolioAnalysis
//

import Foundation

/// The engine that classifies positions into meaningful categories.
/// This version uses ONLY the fields that currently exist in your models.
/// As your models grow (e.g., account type, volatility, premium score),
/// this engine can be expanded without breaking anything.
struct PortfolioAnalyzer {

    init() {}

    // MARK: - Classification Entry Point
    func classify(position: ImportedPosition,
                  result: PortfolioAnalysisResult) -> PositionClassification {

        // Cash is always "Leave Alone"
        if position.isCash || result.isCash {
            return .leaveAlone
        }

        let shares = result.quantity
        let isUnderwater = result.currentPrice < result.costBasis

        // MARK: - Income Engine (100+ shares)
        if shares >= 100 {
            return .incomeEngine
        }

        // MARK: - Repair Candidate (<100 shares + underwater)
        if shares < 100 && isUnderwater {
            return .repairCandidate
        }

        // MARK: - Income Candidate (<100 shares, not underwater)
        if shares < 100 && !isUnderwater {
            return .incomeCandidate
        }

        // MARK: - Fallback
        return .leaveAlone
    }
}
