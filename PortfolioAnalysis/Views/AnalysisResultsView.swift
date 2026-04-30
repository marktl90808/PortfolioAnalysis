//
//  AnalysisResultsView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Totals Section
            totalsSection

            // MARK: - Results List
            List {
                ForEach(viewModel.analysisResults) { result in
                    let dayChange = dayChange(for: result)

                    if viewModel.priceHistory[result.symbol] != nil {
                        NavigationLink {
                            StockDetailView(initialSymbol: result.symbol, viewModel: viewModel)
                        } label: {
                            PositionRowView(result: result, dayChange: dayChange)
                        }
                    } else {
                        PositionRowView(result: result, dayChange: dayChange)
                    }
                }
            }
        }
        .navigationTitle("Analysis Results")
    }

    // MARK: - Totals Section
    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Portfolio Summary")
                .font(.headline)

            HStack {
                Text("Total Value:")
                Spacer()
                Text(viewModel.analysisResults
                        .map { $0.totalValue }
                        .reduce(0, +),
                     format: .currency(code: "USD"))
            }

            HStack {
                Text("Total Gain/Loss:")
                Spacer()
                Text(viewModel.analysisResults
                        .map { $0.gainLoss }
                        .reduce(0, +),
                     format: .currency(code: "USD"))
            }

            HStack {
                Text("Day Change:")
                Spacer()
                Text(viewModel.dayChangeTotal,
                     format: .currency(code: "USD"))
                    .foregroundColor(viewModel.dayChangeTotal < 0 ? .red : .green)
            }
        }
        .padding(.horizontal)
    }

    private func dayChange(for result: PortfolioAnalysisResult) -> Double {
        guard !result.isCash,
              let history = viewModel.priceHistory[result.symbol],
              history.count >= 2 else { return 0 }

        let latest = history[history.count - 1].close
        let previous = history[history.count - 2].close
        return (latest - previous) * result.quantity
    }
}
