//
//  ImportedPosition+Import.swift
//  PortfolioAnalysis
//

import Foundation

extension ImportedPosition {

    static func from(columns: [String], header: [String]) throws -> ImportedPosition {

        // MARK: - Normalize header names
        func normalize(_ s: String) -> String {
            s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined()
        }

        let normalizedHeader: [String: Int] = {
            var map: [String: Int] = [:]
            for (i, h) in header.enumerated() {
                let key = normalize(h)
                if !key.isEmpty && map[key] == nil {
                    map[key] = i
                }
            }
            return map
        }()

        // MARK: - Lookup helper
        func value(_ aliases: [String]) -> String? {
            for alias in aliases {
                let key = normalize(alias)
                if let idx = normalizedHeader[key], idx < columns.count {
                    let raw = columns[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                    if raw != "-" && !raw.isEmpty { return raw }
                }
            }
            return nil
        }

        // MARK: - Parsing helpers
        func parseDouble(_ raw: String?) -> Double? {
            guard let raw else { return nil }
            var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if s == "-" || s.isEmpty { return nil }

            let isParenNeg = s.hasPrefix("(") && s.hasSuffix(")")
            s = s
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")

            guard let v = Double(s) else { return nil }
            return isParenNeg ? -v : v
        }

        func parseDate(_ raw: String?) -> Date? {
            guard let raw else { return nil }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }

            let formats = [
                "M/d/yy h:mm a 'ET'",
                "M/d/yy h:mm a",
                "MM/dd/yyyy",
                "yyyy-MM-dd"
            ]

            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")

            for f in formats {
                df.dateFormat = f
                if let d = df.date(from: trimmed) { return d }
            }
            return nil
        }

        // MARK: - Extract fields

        let rawTicker = value(["symbol/cusip", "symbol", "ticker"])
        let rawName   = value(["description", "name"]) ?? ""

        // Cash detection
        func isCashLike(_ s: String?) -> Bool {
            guard let s else { return false }
            let n = normalize(s)
            return n.contains("cash")
                || n.contains("moneymarket")
                || n == "----"
        }

        let isCashRow = isCashLike(rawTicker) || isCashLike(rawName)

        let ticker = isCashRow ? "CASH" : (rawTicker ?? "")
        let name   = isCashRow ? (rawName.isEmpty ? "Cash" : rawName) : rawName

        // LPL rounded quantity (display only)
        let quantity = isCashRow ? nil : parseDouble(value(["quantity", "shares", "units"]))

        // Price
        let price = parseDouble(value(["price ($)", "price"]))

        // Value ($)
        let totalValue = parseDouble(value(["value ($)", "value", "marketvalue"]))

        // Unit cost
        let explicitUnitCost = parseDouble(value(["unit cost", "unitcost", "avgcost"]))

        // Total cost basis
        let totalCostBasis = parseDouble(value(["cost basis ($)", "costbasis"]))

        // LPL rule: NEVER recompute cost per share from rounded quantity
        let costBasisPerShare: Double? = {
            if isCashRow { return nil }
            if let unit = explicitUnitCost { return unit }
            return nil
        }()

        let dayChangeAmount = parseDouble(value(["day change ($)", "daychange"]))

        // Cash value
        let cashValue: Double? = {
            if !isCashRow { return nil }
            return totalValue ?? totalCostBasis
        }()

        let acquisitionDate = parseDate(value(["acquisitiondate", "purchasedate"]))

        let accountId =
            value(["account number", "accountname", "accountid"]) ?? ""

        // MARK: - effectiveQuantity (value ÷ price)
        let effectiveQuantity: Double? = {
            guard !isCashRow else { return nil }
            guard let price, price != 0 else { return nil }
            guard let totalValue else { return nil }
            return totalValue / price
        }()

        // MARK: - Construct model
        return ImportedPosition(
            ticker: ticker,
            name: name,
            quantity: quantity,                 // LPL rounded
            effectiveQuantity: effectiveQuantity, // inferred precise
            costBasisPerShare: costBasisPerShare,
            cashValue: cashValue,
            dayChangeAmount: dayChangeAmount,
            acquisitionDate: acquisitionDate,
            accountId: accountId
        )
    }
}
