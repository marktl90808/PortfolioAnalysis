//
//  ImportedPosition.swift
//  PortfolioAnalysis
//

import Foundation

struct ImportedPosition: Identifiable, Codable, Sendable {
    var id: UUID

    var symbol: String
    var name: String
    var quantity: Double
    var price: Double
    var value: Double
    var costBasis: Double?

    // ⭐ NEW FIELD — optional purchase date
    var purchaseDate: Date?

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Double,
        price: Double,
        value: Double,
        costBasis: Double?,
        purchaseDate: Date? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.price = price
        self.value = value
        self.costBasis = costBasis
        self.purchaseDate = purchaseDate
    }
}
extension ImportedPosition {
    var isCash: Bool {
        // Cash-like detection
        if symbol.uppercased().contains("CASH") { return true }
        if name.uppercased().contains("CASH") { return true }

        // If costBasis is nil AND quantity == 1 AND value == price → likely cash
        if costBasis == nil && quantity == 1 && value == price {
            return true
        }

        return false
    }
}

// End of "ImportedPosition.swift"
