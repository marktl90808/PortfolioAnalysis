//
//  AnalysisResultsView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    @State private var sortByPercentBelowHigh = true

    var sortedResults: [PortfolioAnalysisResult] {
        if sortByPercentBelowHigh {
            return viewModel.analysisResults.sorted {
                $0.percentDifferenceFromYearHigh < $1.percentDifferenceFromYearHigh
            }
        } else {
            return viewModel.analysisResults.sorted {
                $0.totalValue > $1.totalValue
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // MARK: - Slope Method Picker
                Picker("Slope method", selection: $viewModel.slopeMethod) {
                    Text("Simple Δ").tag(SlopeMethod.simpleDelta)
                    Text("Linear Regression").tag(SlopeMethod.linearRegression)
                }
                .pickerStyle(.segmented)

                // MARK: - Sort Picker
                Picker("Sort by", selection: $sortByPercentBelowHigh) {
                    Text("% below high").tag(true)
                    Text("Total value").tag(false)
                }
                .pickerStyle(.segmented)

                // MARK: - Portfolio Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Total: \(viewModel.portfolioTotal, format: .currency(code: "USD"))")
                    Text("Cost Basis: \(viewModel.totalCostBasis, format: .currency(code: "USD"))")
                    Text("Total Growth: \(viewModel.totalGrowth, format: .currency(code: "USD"))")
                    Text("Cash: \(viewModel.cashTotal, format: .currency(code: "USD"))")
                    Text("Daily Change: \(viewModel.dayChangeTotal, format: .currency(code: "USD"))")
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

                // MARK: - Results List
                List(sortedResults) { result in
                    PositionRowView(result: result)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Analysis Results")
        }
        .developerLabel("AnalysisResultsView")
    }
}
