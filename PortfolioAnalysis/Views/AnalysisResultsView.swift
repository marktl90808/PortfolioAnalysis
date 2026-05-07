//
//  AnalysisResultsView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // Helper: lookup the ImportedPosition for a symbol
    private func positionName(for symbol: String) -> String {
        viewModel.positions.first(where: { $0.symbol == symbol })?.name ?? ""
    }

    var body: some View {
        List {

            // MARK: - Portfolio Summary
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Portfolio Summary")
                        .font(.headline)

                    HStack {
                        Text("Total Value:")
                        Spacer()
                        Text(viewModel.portfolioTotal, format: .currency(code: currencyCode))
                            .font(.body.weight(.semibold))
                    }

                    HStack {
                        Text("Cash:")
                        Spacer()
                        Text(viewModel.cashTotal, format: .currency(code: currencyCode))
                            .font(.body.weight(.semibold))
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Day Change:")
                        Spacer()
                        Text(viewModel.dayChangeTotal, format: .currency(code: currencyCode))
                            .foregroundColor(viewModel.dayChangeTotal < 0 ? .red : .green)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Analysis Results (Cash removed)
            Section("Holdings") {
                ForEach(
                    viewModel.analysisResults.filter { !$0.isCash },
                    id: \.symbol
                ) { result in

                    NavigationLink(
                        destination: StockDetailView(
                            initialSymbol: result.symbol,
                            viewModel: viewModel,
                            orderedResults: viewModel.analysisResults
                        )
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {

                                // SYMBOL
                                Text(result.symbol)
                                    .font(.headline)

                                // COMPANY NAME (smart title case)
                                let name = positionName(for: result.symbol)
                                if !name.isEmpty {
                                    Text(name.smartTitleCase())
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                // CLASSIFICATION BADGE
                                ClassificationBadgeView(classification: result.classification)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(result.currentPrice, format: .currency(code: currencyCode))
                                    .font(.subheadline.weight(.semibold))

                                Text(result.percentDifferenceFromYearHigh / 100,
                                     format: .percent.precision(.fractionLength(2)))
                                .foregroundColor(result.percentDifferenceFromYearHigh < 0 ? .red : .green)
                                .font(.caption)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Analysis Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}

//
// MARK: - Smart Title Case Extension
//

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

// End of file
