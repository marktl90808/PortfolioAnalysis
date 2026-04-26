//
//  PortfolioImporter.swift
//  PortfolioAnalysis
//

import Foundation

struct PortfolioImporter {
    enum ImportError: Error { case invalidFormat }

    // Very naive CSV parser expecting at least a ticker column; extend as needed
    func parseCSV(_ text: String) throws -> [ImportedPosition] {
        // Split into non-empty lines
        let rows = text
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let headerRow = rows.first else { return [] }
        let header = headerRow
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)

        var positions: [ImportedPosition] = []
        positions.reserveCapacity(rows.count - 1)

        for row in rows.dropFirst() {
            let cols = row
                .split(separator: ",", omittingEmptySubsequences: false)
                .map(String.init)

            if let position = try? ImportedPosition.from(columns: cols, header: header) {
                positions.append(position)
            }
        }

        return positions
    }
}

