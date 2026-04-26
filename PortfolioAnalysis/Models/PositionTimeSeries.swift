//
//  PositionTimeSeries.swift
//  PortfolioAnalysis
//
//  Created by Mark Leonard on 4/22/2026.
//
import Foundation

/// A position combined with its historical price data.
struct PositionTimeSeries: Sendable {
    /// The imported position metadata.
    let position: ImportedPosition

    /// Historical price points, sorted ascending by date.
    let history: [PricePoint]

    /// The most recent closing price.
    var latestPrice: Double? {
        history.last?.close
    }

    /// The highest price in the last 52 weeks (approx. 252 trading days).
    var yearHighPrice: Double? {
        history.suffix(252).map(\.close).max()
    }
}
