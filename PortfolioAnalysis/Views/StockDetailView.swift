//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct StockDetailView: View {
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let position: ImportedPosition
    let history: [PricePoint]
    let referenceHigh: Double?
    let referenceHighColor: Color
    let range: TimeRange
    let showMA20: Bool
    let showMA200: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    // MARK: - Computed Values

    private var latestPrice: Double {
        history.last?.close ?? position.price
    }

    private var marketValue: Double {
        latestPrice * position.quantity
    }

    private var dayChangeAmount: Double {
        guard history.count >= 2 else { return 0 }
        let last = history[history.count - 1].close
        let prev = history[history.count - 2].close
        return (last - prev) * position.quantity
    }

    private var dayChangePercent: Double {
        guard history.count >= 2 else { return 0 }
        let last = history[history.count - 1].close
        let prev = history[history.count - 2].close
        return (last - prev) / prev
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // MARK: - HEADER
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.symbol)
                        .font(.largeTitle.bold())

                    if !position.name.isEmpty {
                        Text(position.name.smartTitleCase())
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }


                    HStack(spacing: 12) {
                        Text(latestPrice, format: .currency(code: currencyCode))
                            .font(.title2.bold())

                        Text(dayChangeAmount, format: .currency(code: currencyCode))
                            .foregroundColor(dayChangeAmount >= 0 ? .green : .red)

                        Text(dayChangePercent, format: .percent.precision(.fractionLength(2)))
                            .foregroundColor(dayChangeAmount >= 0 ? .green : .red)
                    }
                }
                .padding(.horizontal)

                // MARK: - CHART
                StockPriceChartView(
                    history: history,
                    range: range,
                    showMA20: showMA20,
                    showMA200: showMA200,
                    referenceHigh: referenceHigh,
                    referenceHighColor: referenceHighColor,
                    quantity: position.quantity,
                    costBasis: position.costBasis,
                    purchaseDate: position.purchaseDate,
                    unitCost: position.unitCost ?? 0
                )
                .frame(height: 300)
                .padding(.horizontal)

                // MARK: - POSITION DETAILS
                VStack(alignment: .leading, spacing: 12) {
                    Text("Position Details")
                        .font(.headline)
                        .padding(.bottom, 4)

                    // ⭐ Tappable quantity row
                    Button {
                        showingEdit = true
                    } label: {
                        detailRow(
                            label: "Quantity:",
                            value: String(position.quantity)
                        )
                    }
                    .buttonStyle(.plain)

                    detailRow(
                        label: "Market Value:",
                        value: marketValue.formatted(.currency(code: currencyCode))
                    )

                    if let unitCost = position.unitCost {
                        let totalCost = (position.costBasis ?? (unitCost * position.quantity))

                        detailRow(
                            label: "Cost:",
                            value: "at \(unitCost.formatted(.currency(code: currencyCode))) × \(String(position.quantity)) = \(totalCost.formatted(.currency(code: currencyCode)))"
                        )
                    } else if let costBasis = position.costBasis {
                        detailRow(
                            label: "Cost:",
                            value: costBasis.formatted(.currency(code: currencyCode))
                        )
                    }

                    if let purchaseDate = position.purchaseDate {
                        detailRow(
                            label: "Purchased:",
                            value: purchaseDate.formatted(.dateTime.month().day().year())
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)

        // ⭐ Correct parameter order for EditPositionView
        .sheet(isPresented: $showingEdit) {
            EditPositionView(viewModel: viewModel, position: position)
        }
    }

    // MARK: - Detail Row Helper

    @ViewBuilder
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

//
// MARK: - COMPATIBILITY INITIALIZER
//

extension StockDetailView {
    init(
        initialSymbol: String,
        viewModel: PortfolioAnalysisViewModel,
        orderedResults: [PortfolioAnalysisResult]
    ) {
        let position = viewModel.positions.first { $0.symbol == initialSymbol }
            ?? viewModel.positions.first!

        let history = viewModel.priceHistory[initialSymbol] ?? []
        let referenceHigh = history.map(\.close).max()

        self.init(
            viewModel: viewModel,
            position: position,
            history: history,
            referenceHigh: referenceHigh,
            referenceHighColor: .blue,
            range: .oneYear,
            showMA20: false,
            showMA200: false
        )
    }
}
