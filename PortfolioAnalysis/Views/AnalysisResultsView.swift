import SwiftUI

struct AnalysisResultsView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

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

            // MARK: - Holdings
            Section("Holdings") {
                ForEach(viewModel.sortedResultsExcludingCash(), id: \.symbol) { result in

                    NavigationLink {
                        StockDetailPagerView(
                            viewModel: viewModel,
                            orderedResults: viewModel.sortedResultsExcludingCash(),
                            initialSymbol: result.symbol
                        )
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {

                                Text(result.symbol)
                                    .font(.headline)

                                let name = positionName(for: result.symbol)
                                if !name.isEmpty {
                                    Text(name)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

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

// End of AnalysisResultsView.swift

