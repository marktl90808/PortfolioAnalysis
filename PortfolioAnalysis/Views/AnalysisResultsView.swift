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
                    PositionRowView(result: result)
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
        }
        .padding(.horizontal)
    }
}
