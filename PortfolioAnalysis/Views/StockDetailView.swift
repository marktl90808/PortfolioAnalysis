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

    private var holdingDescription: String {
        let name = editablePosition?.name.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return name.isEmpty ? result.symbol : name
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

    private var chartTrendColor: Color {
        let sorted = history.sorted { $0.date < $1.date }
        let start = range.dateWindow(from: sorted.last?.date ?? Date())
        let filtered = sorted.filter { $0.date >= start }
        guard let first = filtered.first?.close, let last = filtered.last?.close else { return .secondary }
        if last > first { return .green }
        if last < first { return .red }
        return .secondary
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

                    Text(holdingDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(result.currentPrice, format: .currency(code: currencyCode))
                        .font(.title2)
                        .foregroundColor(.primary)

                    if !result.isCash {
                        compact52WHSummary
                    }

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

                timeRangeSelector

                StockPriceChartView(
                    history: history,
                    range: range,
                    showMA20: showMA20,
                    showMA200: showMA200,
                    referenceHigh: result.yearHighPrice,
                    referenceHighColor: chartTrendColor
                )
                .frame(height: 260)
                .padding(.horizontal, 8)

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

                if !result.isCash {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trend / Velocity")
                            .font(.headline)

                        HStack {
                            Text("5D:")
                            Spacer()
                            Text(slopeText(result.shortTermSlope))
                                .foregroundColor(slopeColor(result.shortTermSlope))
                        }

                        HStack {
                            Text("20D:")
                            Spacer()
                            Text(slopeText(result.mediumTermSlope))
                                .foregroundColor(slopeColor(result.mediumTermSlope))
                        }

                        HStack {
                            Text("60D:")
                            Spacer()
                            Text(slopeText(result.longTermSlope))
                                .foregroundColor(slopeColor(result.longTermSlope))
                        }

                        HStack {
                            Text("Direction:")
                            Spacer()
                            Text(directionChangeLabel(result.directionChange))
                                .foregroundColor(directionColor(result.directionChange))
                        }
                    }
                    .padding(.horizontal)
                }

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
        .developerLabel("StockDetailView")
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

    private func slopeText(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode))
    }

    private func slopeColor(_ value: Double) -> Color {
        value < 0 ? .red : (value > 0 ? .green : .secondary)
    }

    private func directionChangeLabel(_ direction: TrendDirectionChange) -> String {
        switch direction {
        case .none:
            return "none"
        case .turningUp:
            return "turning up"
        case .turningDown:
            return "turning down"
        }
    }

    private func directionColor(_ direction: TrendDirectionChange) -> Color {
        switch direction {
        case .none:
            return .secondary
        case .turningUp:
            return .green
        case .turningDown:
            return .red
        }
    }

    private var timeRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TimeRange.allCases) { r in
                    Text(r.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(r == range ? .primary : .secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(r == range ? Color.blue.opacity(0.18) : Color.clear)
                        .clipShape(Capsule())
                        .onTapGesture { range = r }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compact52WHSummary: some View {
        HStack(spacing: 12) {
            summaryItem(
                title: "52WH",
                value: String(format: "%.2f%%", result.percentDifferenceFromYearHigh),
                valueColor: result.percentDifferenceFromYearHigh < 0 ? .red : .green
            )

            summaryItem(
                title: "/sh",
                value: formattedCurrency(highImpactPerShare),
                valueColor: highImpactPerShare < 0 ? .red : .green
            )

            summaryItem(
                title: "Total",
                value: formattedCurrency(highImpactTotal),
                valueColor: highImpactTotal < 0 ? .red : .green
            )
        }
        .padding(.top, 2)
    }

    private func summaryItem(title: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
    }
}
