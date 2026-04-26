//
//  PortfolioImporter.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioImporter {

    // MARK: - Public Entry Point (CSV file import)
    func parseCSVFile(_ text: String) throws -> [ImportedPosition] {
        let rows = cleanAndSplitCSV(text)
        guard !rows.isEmpty else { return [] }

        let header = rows[0]
        let body = Array(rows.dropFirst())

        return try body.compactMap { try ImportedPosition.from(columns: $0, header: header) }
    }

    // MARK: - CSV Splitter
    private func cleanAndSplitCSV(_ text: String) -> [[String]] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { line in
                line.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            }
            .filter { !$0.isEmpty }
    }
}

// End of PortfolioImporter.swifr
