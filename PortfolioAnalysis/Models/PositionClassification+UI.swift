//
//  PositionClassification+UI.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 5/5/2026.
//

import SwiftUI

extension PositionClassification {

    var label: String {
        switch self {
        case .incomeEngine: return "Income Engine"
        case .incomeCandidate: return "Income Candidate"
        case .iraIncomeEngine: return "IRA Income Engine"
        case .iraGrowthPosition: return "IRA Growth"
        case .repairCandidate: return "Repair Candidate"
        case .leaveAlone: return "Leave Alone"
        }
    }

    var icon: String {
        switch self {
        case .incomeEngine: return "flame.fill"
        case .incomeCandidate: return "bolt.fill"
        case .iraIncomeEngine: return "shield.lefthalf.filled"
        case .iraGrowthPosition: return "leaf.fill"
        case .repairCandidate: return "wrench.fill"
        case .leaveAlone: return "pause.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .incomeEngine: return .orange
        case .incomeCandidate: return .yellow
        case .iraIncomeEngine: return .blue
        case .iraGrowthPosition: return .green
        case .repairCandidate: return .red
        case .leaveAlone: return .gray
        }
    }
}
