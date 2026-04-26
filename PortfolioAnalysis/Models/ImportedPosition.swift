//
//  ImportedPosition.swift
//  PortfolioAnalysis
//

import Foundation

struct ImportedPosition: Identifiable, Codable {
    let id: UUID            // ← no default value

    let symbol: String
    let name: String

    /// Quantity of shares (LPL-compatible)
    var quantity: Double

    /// Latest known price (from import)
    let price: Double

    /// Total value (qty * price)
    let value: Double

    /// Optional cost basis (LPL sometimes omits this)
    let costBasis: Double?
}

// MARK: - Cash Detection
extension ImportedPosition {
    var isCash: Bool {
        let s = symbol.uppercased()
        let n = name.uppercased()

        return s == "----"
            || s == "CASH"
            || n.contains("CASH")
            || n.contains("MONEY MARKET")
            || (price == 1.0 && costBasis == nil)
    }
}
