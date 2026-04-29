//
//  TrendClassification+UI.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/28/2026.
//

import SwiftUI

extension TrendClassification {

    /// Short label for UI badges
    var shortLabel: String {
        switch self {
        case .strongGrowth: return "Strong"
        case .growth:       return "Growth"
        case .flat:         return "Flat"
        case .erratic:      return "Erratic"
        case .downward:     return "Down"
        case .getOut:       return "Exit"
        }
    }

    /// SF Symbol for UI badges
    var icon: String {
        switch self {
        case .strongGrowth: return "arrow.up.right.circle.fill"
        case .growth:       return "arrow.up.right"
        case .flat:         return "minus.circle"
        case .erratic:      return "waveform.path.ecg"
        case .downward:     return "arrow.down.right"
        case .getOut:       return "exclamationmark.triangle.fill"
        }
    }

    /// Color for UI badges
    var color: Color {
        switch self {
        case .strongGrowth: return .green
        case .growth:       return .mint
        case .flat:         return .gray
        case .erratic:      return .orange
        case .downward:     return .red
        case .getOut:       return .purple
        }
    }
}
