//
//  String+SmartTitleCase.swift
//  PortfolioAnalysis
//

import Foundation

extension String {
    func smartTitleCase() -> String {
        let acronyms: Set<String> = [
            "ETF", "ETFS", "USA", "US", "S&P", "REIT", "AI", "EV", "ADR",
            "LP", "LLC", "PLC", "NAV", "EPS", "PE", "P/E"
        ]

        let smallWords: Set<String> = [
            "and", "or", "the", "a", "an", "of", "for", "in", "on", "to"
        ]

        let words = self
            .split(separator: " ")
            .map { String($0) }

        var result: [String] = []

        for (index, rawWord) in words.enumerated() {
            let word = rawWord.trimmingCharacters(in: .whitespaces)
            let upper = word.uppercased()
            let lower = word.lowercased()

            if acronyms.contains(upper) {
                result.append(upper)
                continue
            }

            if word == upper {
                result.append(upper)
                continue
            }

            if smallWords.contains(lower) && index != 0 {
                result.append(lower)
                continue
            }

            if word.contains("-") {
                let parts = word.split(separator: "-").map { String($0) }
                let fixed = parts.map { $0.smartTitleCase() }.joined(separator: "-")
                result.append(fixed)
                continue
            }

            if word.contains("/") {
                let parts = word.split(separator: "/").map { String($0) }
                let fixed = parts.map { $0.smartTitleCase() }.joined(separator: "/")
                result.append(fixed)
                continue
            }

            result.append(lower.capitalized)
        }

        return result.joined(separator: " ")
    }
}
