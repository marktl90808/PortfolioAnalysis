//
//  ImportedPosition+Import.swift
//  PortfolioAnalysis
//

import Foundation

extension ImportedPosition {

    // MARK: - TSV Paste Import
    static func parseTSV(_ text: String) throws -> [ImportedPosition] {
        let rows = cleanAndSplitTSV(text)
        guard !rows.isEmpty else { return [] }

        let header = rows[0]
        let body = Array(rows.dropFirst())

        return try body.compactMap { try ImportedPosition.from(columns: $0, header: header) }
    }

    // MARK: - TSV Splitter
    private static func cleanAndSplitTSV(_ text: String) -> [[String]] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { line in
                line.split(separator: "\t").map { String($0).trimmingCharacters(in: .whitespaces) }
            }
            .filter { !$0.isEmpty }
    }

    // MARK: - Construct ImportedPosition from row
    static func from(columns: [String], header: [String]) throws -> ImportedPosition {

        // Normalize header keys
        func normalize(_ s: String) -> String {
            s.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined()
        }

        let headerMap: [String: Int] = {
            var map: [String: Int] = [:]
            for (i, h) in header.enumerated() {
                let key = normalize(h)
                if !key.isEmpty { map[key] = i }
            }
            return map
        }()

        func value(_ aliases: [String]) -> String? {
            for alias in aliases {
                let key = normalize(alias)
                if let idx = headerMap[key], idx < columns.count {
                    let raw = columns[idx].trimmingCharacters(in: .whitespaces)
                    if !raw.isEmpty, raw != "-" { return raw }
                }
            }
            return nil
        }

        func parseDouble(_ raw: String?) -> Double? {
            guard let raw else { return nil }
            var s = raw.trimmingCharacters(in: .whitespaces)
            if s.isEmpty || s == "-" { return nil }

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

        // MARK: - Extract fields

        let rawSymbol = value(["symbol", "ticker", "symbolcusip"])
        let rawName   = value(["name", "description"]) ?? ""

        let quantity = parseDouble(value(["quantity", "shares", "units"])) ?? 0
        let price    = parseDouble(value(["price", "price$", "price($)"]))
        let totalVal = parseDouble(value(["value", "value$", "marketvalue"]))
        let costBasis = parseDouble(value(["costbasis", "costbasis$", "costbasis($)"]))

        // Compute missing price/value
        let finalPrice: Double = {
            if let p = price { return p }
            if quantity > 0, let v = totalVal { return v / quantity }
            return 0
        }()

        let finalValue: Double = {
            if let v = totalVal { return v }
            return quantity * finalPrice
        }()

        let symbol = rawSymbol?.uppercased() ?? ""

        guard !symbol.isEmpty else {
            throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing symbol"])
        }

        return ImportedPosition(
            id: UUID(),
            symbol: symbol,
            name: rawName,
            quantity: quantity,
            price: finalPrice,
            value: finalValue,
            costBasis: costBasis
        )
    }
}

//End of file

