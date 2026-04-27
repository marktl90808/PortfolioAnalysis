//
//  TrendCategory.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/26/2026.
//


//
//  TrendCategory.swift
//  PortfolioAnalysis
//
//  Basic trend classification used by TrendAnalysis.
//

import Foundation

enum TrendCategory: String, Codable {
    case growth
    case flat
    case downward
    case erratic
    case getOut
}
