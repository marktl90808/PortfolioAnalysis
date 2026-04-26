//
//  TrendClassification.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//

import Foundation

/// High‑level classification of a stock's trend.
enum TrendClassification: String, Sendable, Codable, CustomStringConvertible {
    case strongGrowth
    case growth
    case flat
    case erratic
    case downward
    case getOut

    var description: String {
        switch self {
        case .strongGrowth:
            return "At or above the 52-week high"
        case .growth:
            return "Close to the 52-week high"
        case .flat:
            return "Moderately below the 52-week high"
        case .erratic:
            return "Volatile"
        case .downward:
            return "Well below the 52-week high"
        case .getOut:
            return "Far below the 52-week high"
        }
    }
}
