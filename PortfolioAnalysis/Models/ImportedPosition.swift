//
//  ImportedPosition.swift
//  PortfolioAnalysis
//

import Foundation

// MARK: - ImportedPosition Model

struct ImportedPosition: Identifiable, Codable, Sendable {
    var id: UUID

    // Core identity
    var symbol: String
    var name: String

    // Position data
    var quantity: Double
    var price: Double          // market price (updated from market data)
    var value: Double          // market value = price * quantity

    // Cost data
    var costBasis: Double?     // total cost paid
    var unitCost: Double?      // ⭐ NEW: price paid per share (from brokerage import)

    // Optional purchase date
    var purchaseDate: Date?

    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        quantity: Double,
        price: Double,
        value: Double,
        costBasis: Double?,
        unitCost: Double?,
        purchaseDate: Date?
    ) {
        self.id = id
        self.symbol = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        self.name = name.smartTitleCase().trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantity = quantity
        self.price = price
        self.value = value
        self.costBasis = costBasis
        self.unitCost = unitCost
        self.purchaseDate = purchaseDate
    }


}

// MARK: - Cash Detection

extension ImportedPosition {
    var isCash: Bool {
        // Cash-like detection
        if symbol.uppercased().contains("CASH") { return true }
        if name.uppercased().contains("CASH") { return true }

        // Money market / sweep accounts often have:
        // quantity == value == price == 1.00
        if costBasis == nil && quantity == 1 && value == price {
            return true
        }

        return false
    }
}

// MARK: - TSV Parsing Helpers

private extension String {
    func cleanCurrency() -> String {
        self.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "(", with: "-")
            .replacingOccurrences(of: ")", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanNumber() -> String {
        self.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parseDate() -> Date? {
        let formats = [
            "M/d/yy h:mm a",
            "M/d/yy h:mm a 'ET'",
            "M/d/yy",
            "M/d/yyyy",
            "M/d/yyyy h:mm a",
            "M/d/yyyy h:mm a 'ET'"
        ]

        for format in formats {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = format
            if let date = df.date(from: self) {
                return date
            }
        }
        return nil
    }
}

// MARK: - TSV Parser

extension ImportedPosition {

    static func parseTSV(_ text: String) throws -> [ImportedPosition] {
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard let headerLine = lines.first else { return [] }

        let headers = headerLine.components(separatedBy: "\t")
        var positions: [ImportedPosition] = []

        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: "\t")
            if columns.count != headers.count { continue }

            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                row[header] = columns[index]
            }

            // Extract fields
            let symbol = row["Symbol/CUSIP"]?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased() ?? ""
            let description = (row["Description"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? symbol)
                .smartTitleCase()


            let quantity = Double(row["Quantity"]?.cleanNumber() ?? "") ?? 0
            let marketPrice = Double(row["Price ($)"]?.cleanCurrency() ?? "") ?? 0
            let value = Double(row["Value ($)"]?.cleanCurrency() ?? "") ?? (marketPrice * quantity)

            let costBasis = Double(row["Cost Basis ($)"]?.cleanCurrency() ?? "") ?? nil

            // ⭐ NEW: Unit Cost
            let unitCost = Double(row["Unit Cost"]?.cleanCurrency() ?? "") ?? nil

            // Purchase date
            let purchaseDate = row["Price as Of"]?.parseDate()

            // Build the position
            let position = ImportedPosition(
                symbol: symbol,
                name: description,
                quantity: quantity,
                price: marketPrice,
                value: value,
                costBasis: costBasis,
                unitCost: unitCost,          // ⭐ NEW
                purchaseDate: purchaseDate
            )

            positions.append(position)
        }

        return positions
    }
}
