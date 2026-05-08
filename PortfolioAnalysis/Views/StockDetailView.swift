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
    let showMA20: Bool
    let showMA200: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    @State private var confirmSell = false

    @State private var selectedRange: TimeRange = .oneYear

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

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
                        Text(position.name)
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

                // MARK: - RANGE PICKER
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        rangeButton(.oneDay, label: "1D")
                        rangeButton(.oneWeek, label: "1W")
                        rangeButton(.oneMonth, label: "1M")
                        rangeButton(.threeMonths, label: "3M")
                        rangeButton(.sixMonths, label: "6M")
                        rangeButton(.oneYear, label: "1Y")
                        rangeButton(.ytd, label: "YTD")
                        rangeButton(.sincePurchase, label: "Since Buy")
                    }
                    .padding(.horizontal)
                }

                // MARK: - CHART
                StockPriceChartView(
                    history: history,
                    range: selectedRange,
                    showMA20: showMA20,
                    showMA200: showMA200,
                    referenceHigh: referenceHigh,
                    referenceHighColor: referenceHighColor,
                    quantity: position.quantity,
                    costBasis: position.costBasis,
                    purchaseDate: position.purchaseDate,
                    unitCost: position.unitCost
                )
                .frame(height: 300)
                .padding(.horizontal)

                // MARK: - POSITION DETAILS
                VStack(alignment: .leading, spacing: 12) {
                    Text("Position Details")
                        .font(.headline)
                        .padding(.bottom, 4)

                    Button {
                        showingEdit = true
                    } label: {
                        detailRow(label: "Quantity:", value: String(position.quantity))
                    }
                    .buttonStyle(.plain)

                    detailRow(
                        label: "Market Value:",
                        value: marketValue.formatted(.currency(code: currencyCode))
                    )

                    if let unitCost = position.unitCost {
                        let totalCost = unitCost * position.quantity
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

                    Button(role: .destructive) {
                        confirmSell = true
                    } label: {
                        Text("Sell Position")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.top, 12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEdit) {
            EditPositionView(viewModel: viewModel, position: position)
        }
        .confirmationDialog("Sell this position?", isPresented: $confirmSell) {
            Button("Sell", role: .destructive) {
                Task {
                    await viewModel.sellPosition(symbol: position.symbol)
                    await MainActor.run { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline.weight(.semibold))
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func rangeButton(_ value: TimeRange, label: String) -> some View {
        Button {
            selectedRange = value
        } label: {
            Text(label)
                .font(.caption)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(selectedRange == value ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

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
            showMA20: false,
            showMA200: false
        )
    }
}
// End of file StockDetailView.swift

