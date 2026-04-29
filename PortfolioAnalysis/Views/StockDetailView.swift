//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct StockDetailView: View {
    let initialSymbol: String
    @ObservedObject var viewModel: PortfolioAnalysisViewModel

    @State private var selectedSymbol: String

    init(initialSymbol: String, viewModel: PortfolioAnalysisViewModel) {
        self.initialSymbol = initialSymbol
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self._selectedSymbol = State(initialValue: initialSymbol)
    }

    private var orderedResults: [PortfolioAnalysisResult] {
        viewModel.analysisResults
    }

    private var selectedIndex: Int? {
        orderedResults.firstIndex(where: { $0.symbol == selectedSymbol })
    }

    private var pageIndicatorText: String? {
        guard orderedResults.count > 1 else { return nil }
        let page = (selectedIndex ?? 0) + 1
        return "\(page) of \(orderedResults.count)"
    }

    var body: some View {
        Group {
            if orderedResults.isEmpty {
                ContentUnavailableView("No Analysis Results", systemImage: "chart.line.uptrend.xyaxis")
            } else {
                TabView(selection: $selectedSymbol) {
                    ForEach(Array(orderedResults.enumerated()), id: \.element.symbol) { index, result in
                        StockDetailPage(
                            result: result,
                            history: viewModel.priceHistory[result.symbol] ?? [],
                            viewModel: viewModel,
                            pageIndex: index + 1,
                            pageCount: orderedResults.count
                        )
                        .tag(result.symbol)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onAppear {
                    if selectedIndex == nil {
                        selectedSymbol = initialSymbol
                    }
                    if selectedIndex == nil, let first = orderedResults.first {
                        selectedSymbol = first.symbol
                    }
                }
                .onChange(of: orderedResults.map(\.symbol)) { _, newSymbols in
                    if !newSymbols.contains(selectedSymbol), let first = orderedResults.first {
                        selectedSymbol = first.symbol
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StockDetailPage: View {
    let result: PortfolioAnalysisResult
    let history: [PricePoint]
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let pageIndex: Int
    let pageCount: Int

    @State private var range: TimeRange = .oneMonth
    @State private var showMA20 = false
    @State private var showMA200 = false
    @State private var showingEditSheet = false

    private var editablePosition: ImportedPosition? {
        viewModel.positions.first(where: { $0.symbol == result.symbol })
    }

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var highImpactPerShare: Double {
        result.dollarDifferenceFromYearHigh
    }

    private var highImpactTotal: Double {
        highImpactPerShare * result.quantity
    }

    private var nearHighThreshold: Double { 100 }

    private var isNearHigh: Bool {
        abs(highImpactTotal) < nearHighThreshold
    }

    private var pageIndicatorText: String? {
        pageCount > 1 ? "\(pageIndex) of \(pageCount)" : nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(result.symbol)
                        .font(.largeTitle.bold())

                    Text(result.currentPrice, format: .currency(code: currencyCode))
                        .font(.title2)
                        .foregroundColor(.primary)

                    let pct = result.percentDifferenceFromYearHigh
                    Text(String(format: "%.2f%% from 52WH", pct))
                        .font(.caption)
                        .foregroundColor(pct < 0 ? .red : .green)

                    if let pageIndicatorText {
                        Text(pageIndicatorText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit Position", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .disabled(editablePosition == nil)

                StockPriceChartView(
                    history: history,
                    range: range,
                    showMA20: showMA20,
                    showMA200: showMA200,
                    referenceHigh: result.yearHighPrice
                )
                .frame(height: 260)
                .padding(.horizontal, 8)

                HStack(spacing: 10) {
                    ForEach(TimeRange.allCases) { r in
                        Text(r.rawValue)
                            .font(.caption)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(r == range ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                            .onTapGesture { range = r }
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("52WH Impact")
                        .font(.headline)

                    HStack {
                        Text("Per share:")
                        Spacer()
                        Text(highImpactPerShare, format: .currency(code: currencyCode))
                            .foregroundColor(highImpactPerShare < 0 ? .red : .green)
                    }

                    HStack {
                        Text("Qty × impact:")
                        Spacer()
                        Text(highImpactTotal, format: .currency(code: currencyCode))
                            .foregroundColor(highImpactTotal < 0 ? .red : .green)
                    }

                    Text(isNearHigh ? "Near High price... enjoy." : impactMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    if !isNearHigh {
                        Text("No noteworthy news to report.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 20) {
                    Toggle("MA20", isOn: $showMA20)
                    Toggle("MA200", isOn: $showMA200)
                }
                .padding(.horizontal)
                .toggleStyle(.switch)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Position Details")
                        .font(.headline)

                    HStack {
                        Text("Shares:")
                        Spacer()
                        Text(result.quantity, format: .number.precision(.fractionLength(3)))
                    }

                    HStack {
                        Text("Cost Basis:")
                        Spacer()
                        Text(result.costBasis, format: .currency(code: currencyCode))
                    }

                    HStack {
                        Text("Current Value:")
                        Spacer()
                        Text(result.totalValue, format: .currency(code: currencyCode))
                    }

                    HStack {
                        Text("52WH:")
                        Spacer()
                        Text(result.yearHighPrice, format: .currency(code: currencyCode))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(result.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) {
            if let position = editablePosition {
                NavigationStack {
                    EditPositionView(viewModel: viewModel, position: position)
                }
            }
        }
    }

    private var impactMessage: String {
        if highImpactTotal < 0 {
            return "Below 52WH by \(formattedCurrency(highImpactTotal)) across your shares."
        } else if highImpactTotal > 0 {
            return "Above 52WH by \(formattedCurrency(highImpactTotal)) across your shares."
        } else {
            return "At the 52WH level."
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode))
    }
}
