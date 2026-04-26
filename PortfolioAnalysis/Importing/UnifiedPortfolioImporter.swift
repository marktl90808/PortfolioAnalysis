////
////  UnifiedPortfolioImporter.swift
////  PortfolioAnalysis
////
////  Updated for full LPL Financial CSV support
////
//
//import Foundation
//import SwiftUI
//
//struct UnifiedPortfolioImporter {
//
//    // MARK: - Column Aliases (LPL + generic)
//    private let columnAliases: [String: [String]] = [
//
//        // Ticker
//        "ticker": [
//            "ticker", "symbol", "symbolcusip", "symbol/cusip"
//        ],
//
//        // Quantity
//        "quantity": [
//            "quantity", "qty", "shares"
//        ],
//
//        // Market Value
//        "marketvalue": [
//            "value", "value ($)", "marketvalue", "value($)"
//        ],
//
//        // Price
//        "price": [
//            "price", "price ($)", "lastprice"
//        ],
//
//        // Day Change
//        "daychangeamount": [
//            "day change ($)", "daychange", "daychangeamount"
//        ],
//
//        // Cost Basis Per Share
//        "costbasispershare": [
//            "unit cost", "unitcost", "costpershare"
//        ],
//
//        // Total Cost Basis
//        "costbasis": [
//            "cost basis ($)", "costbasis", "totalcost"
//        ],
//
//        // Unrealized Gain/Loss
//        "unrealizedpl": [
//            "unrealized g/l ($)", "unrealizedpl", "gainloss"
//        ],
//
//        // Unrealized Gain/Loss Percent
//        "unrealizedplpercent": [
//            "unrealized g/l (%)", "unrealizedplpercent", "gainlosspercent"
//        ],
//
//        // Acquisition Date (LPL does NOT provide this)
//        "acquisitiondate": [
//            "acquisitiondate", "purchase date"
//        ]
//    }
//
//    // MARK: - Public Import Function
//    func importCSV(_ text: String) throws -> [ImportedPosition] {
//
//        let rows = text.components(separatedBy: .newlines)
//            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
//
//        guard let headerRow = rows.first else {
//            throw ImportError.invalidFormat("Missing header row.")
//        }
//
//        let headers = headerRow
//            .split(separator: ",")
//            .map { normalize($0) }
//
//        let mappedHeaders = mapHeaders(headers)
//
//        var positions: [ImportedPosition] = []
//
//        for row in rows.dropFirst() {
//            let cols = row.split(separator: ",", omittingEmptySubsequences: false)
//                .map { String($0).trimmingCharacters(in: .whitespaces) }
//
//            if cols.count == 0 { continue }
//
//            let position = parseRow(cols, mappedHeaders: mappedHeaders)
//            if let p = position {
//                positions.append(p)
//            }
//        }
//
//        return positions
//    }
//
//    // MARK: - Header Normalization
//    private func normalize(_ raw: Substring) -> String {
//        raw
//            .lowercased()
//            .replacingOccurrences(of: " ", with: "")
//            .replacingOccurrences(of: "(", with: "")
//            .replacingOccurrences(of: ")", with: "")
//            .replacingOccurrences(of: "$", with: "")
//            .replacingOccurrences(of: "/", with: "")
//    }
//
//    // MARK: - Map CSV Headers → Internal Keys
//    private func mapHeaders(_ headers: [String]) -> [String: Int] {
//        var result: [String: Int] = [:]
//
//        for (index, header) in headers.enumerated() {
//            for (canonical, aliases) in columnAliases {
//                if aliases.contains(header) {
//                    result[canonical] = index
//                }
//            }
//        }
//
//        return result
//    }
//
//    // MARK: - Parse a Single Row
//    private func parseRow(_ cols: [String], mappedHeaders: [String: Int]) -> ImportedPosition? {
//
//        func value(_ key: String) -> String? {
//            guard let idx = mappedHeaders[key], idx < cols.count else { return nil }
//            let v = cols[idx].trimmingCharacters(in: .whitespaces)
//            return v.isEmpty ? nil : v
//        }
//
//        let ticker = value("ticker") ?? ""
//        if ticker.isEmpty { return nil }
//
//        let quantity = value("quantity").flatMap { Double($0) }
//        let price = value("price").flatMap { Double($0) }
//        let marketValue = value("marketvalue").flatMap { Double($0) }
//        let dayChange = value("daychangeamount").flatMap { Double($0) }
//        let costBasisPerShare = value("costbasispershare").flatMap { Double($0) }
//        let costBasis = value("costbasis").flatMap { Double($0) }
//        let unrealizedPL = value("unrealizedpl").flatMap { Double($0) }
//        let unrealizedPLPercent = value("unrealizedplpercent").flatMap { Double($0) }
//
//        // LPL does NOT provide acquisition date → fallback to Jan 1 of current year
//        let acquisitionDate: Date = {
//            if let raw = value("acquisitiondate"),
//               let parsed = parseDate(raw) {
//                return parsed
//            }
//            return Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 1, day: 1))!
//        }()
//
//        return ImportedPosition(
//            ticker: ticker,
//            name: "",
//            quantity: quantity,
//            price: price,
//            marketValue: marketValue,
//            dayChangeAmount: dayChange,
//            costBasisPerShare: costBasisPerShare,
//            costBasisTotal: costBasis,
//            unrealizedPL: unrealizedPL,
//            unrealizedPLPercent: unrealizedPLPercent,
//            acquisitionDate: acquisitionDate,
//            accountId: ""
//        )
//    }
//
//    // MARK: - Date Parsing
//    private func parseDate(_ raw: String) -> Date? {
//        let fmts = [
//            "MM/dd/yyyy",
//            "yyyy-MM-dd",
//            "M/d/yyyy"
//        ]
//
//        for fmt in fmts {
//            let df = DateFormatter()
//            df.dateFormat = fmt
//            if let d = df.date(from: raw) { return d }
//        }
//        return nil
//    }
//
//    // MARK: - Errors
//    enum ImportError: Error {
//        case invalidFormat(String)
//    }
//}
