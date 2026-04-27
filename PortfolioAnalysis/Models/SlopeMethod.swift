//
//  SlopeMethod.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/26/2026.
//


//
//  SlopeMethod.swift
//  PortfolioAnalysis
//

import Foundation

enum SlopeMethod: String, Codable, CaseIterable, Identifiable {
    case simpleDelta = "Simple Delta"
    case linearRegression = "Linear Regression"

    var id: String { rawValue }
}
