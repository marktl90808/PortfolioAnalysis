//
//  TrendDirectionChange.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/26/2026.
//


//
//  TrendDirectionChange.swift
//  PortfolioAnalysis
//

import Foundation

enum TrendDirectionChange: String, Codable {
    case improving        // short > medium > long
    case worsening        // short < medium < long
    case bullishReversal  // long < 0, short > 0
    case bearishReversal  // long > 0, short < 0
    case flat             // slopes near zero or inconsistent
}
