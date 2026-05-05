//
//  PositionClassification.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/5/2026.
//


import Foundation

enum PositionClassification: String, Codable, CaseIterable {
    case incomeEngine
    case incomeCandidate
    case iraIncomeEngine
    case iraGrowthPosition
    case repairCandidate
    case leaveAlone
}
