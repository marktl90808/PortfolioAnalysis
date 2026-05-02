//
//  SymbolSeries.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/30/2026.
//


import SwiftUI

struct SymbolSeries: Identifiable {
    let id = UUID()
    let symbol: String
    let history: [PricePoint]
    let color: Color
}
// MARK: End of SymbolSeries.swift
