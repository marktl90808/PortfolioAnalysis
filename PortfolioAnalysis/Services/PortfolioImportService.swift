//
//  PortfolioImportService.swift
//  PortfolioAnalysis
//

import Foundation

protocol PortfolioImportService {
    func importFile(at url: URL) throws -> [ImportedPosition]
    func importPastedText(_ text: String) throws -> [ImportedPosition]
}

struct DefaultPortfolioImportService: PortfolioImportService {

    // MARK: - Import from file
    func importFile(at url: URL) throws -> [ImportedPosition] {
        // Required for sandbox access
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let text = try String(contentsOf: url, encoding: .utf8)
        return try parseCSV(text)
    }


    // MARK: - Import from pasted text
    func importPastedText(_ text: String) throws -> [ImportedPosition] {
        try parseCSV(text)
    }

    // MARK: - Unified CSV parser (RFC‑4180‑style)
    private func parseCSV(_ text: String) throws -> [ImportedPosition] {

        // Split into non-empty lines
        let rows = text
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerRow = rows.first else {
            throw NSError(
                domain: "PortfolioImport",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Missing header row"]
            )
        }

        let header = parseCSVRow(headerRow)

        var positions: [ImportedPosition] = []
        positions.reserveCapacity(rows.count - 1)

        for row in rows.dropFirst() {
            let cols = parseCSVRow(row)
            if cols.isEmpty { continue }

            if let position = try? ImportedPosition.from(columns: cols, header: header) {
                positions.append(position)
            }
        }

        return positions
    }

    // MARK: - CSV row parser (handles quotes + commas)
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false

        var iterator = row.makeIterator()
        while let char = iterator.next() {
            switch char {
            case "\"":
                insideQuotes.toggle()

            case ",":
                if insideQuotes {
                    current.append(char)
                } else {
                    result.append(current.trimmingCharacters(in: .whitespaces))
                    current = ""
                }

            default:
                current.append(char)
            }
        }

        // Append final field
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}
