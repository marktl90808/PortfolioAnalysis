//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI

struct StockDetailView: View {
    let initialSymbol: String
    @ObservedObject var viewModel: PortfolioAnalysisViewModel
    let orderedResultsOverride: [PortfolioAnalysisResult]?

    @State private var selectedSymbol: String

    init(
        initialSymbol: String,
        viewModel: PortfolioAnalysisViewModel,
        orderedResults: [PortfolioAnalysisResult]? = nil
    ) {
        self.initialSymbol = initialSymbol
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.orderedResultsOverride = orderedResults
        self._selectedSymbol = State(initialValue: initialSymbol)
    }

    private var orderedResults: [PortfolioAnalysisResult] {
        orderedResultsOverride ?? viewModel.analysisResults
    }

    private var selectedIndex: Int? {
        orderedResults.firstIndex(where: { $0.symbol == selectedSymbol })
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
                }
                .onChange(of: orderedResults.map(\.symbol)) { _, newSymbols in
                    if !newSymbols.contains(selectedSymbol),
                       let first = orderedResults.first {
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

    private var chartTrendColor: Color {
        let sorted = history.sorted { $0.date < $1.date }
        let start = range.dateWindow(from: sorted.last?.date ?? Date())
        let filtered = sorted.filter { $0.date >= start }

        guard let first = filtered.first?.close,
              let last = filtered.last?.close else {
            return .secondary
        }

        if last > first { return .green }
        if last < first { return .red }
        return .secondary
    }

    private var dayChange: Double? {
        let sorted = history.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted.last!.close - sorted[sorted.count - 2].close
    }

    private var pageIndicatorText: String? {
        pageCount > 1 ? "\(pageIndex) of \(pageCount)" : nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                headerSection
                timeRangeSelector
                chartSection

                // NEW ORDER:
                positionDetailsSection
                impactSection
                trendSection
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(result.symbol)
                .font(.largeTitle.bold())

            Text(holdingDescription)
                .font(.caption)
                .foregroundStyle(.secondary)

            // ⭐ Classification Badge
            ClassificationBadgeView(classification: result.classification)
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.currentPrice, format: .currency(code: currencyCode))
                        .font(.title2)

                    if let dayChange {
                        HStack(spacing: 4) {
                            Text("Day:")
                                .font(.caption)
                            Text(dayChange, format: .currency(code: currencyCode))
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(dayChange < 0 ? .red : (dayChange > 0 ? .green : .secondary))
                    }
                }

                if !result.isCash {
                    compact52WHSummary
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            if let pageIndicatorText {
                Text(pageIndicatorText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(spacing: 8) {

            StockPriceChartView(
                history: history,
                range: range,
                showMA20: showMA20,
                showMA200: showMA200,
                referenceHigh: result.yearHighPrice,
                referenceHighColor: chartTrendColor,
                quantity: result.quantity,
                costBasis: result.costBasis
            )
            .frame(height: 260)
            .padding(.horizontal, 8)

            if let perf = sincePurchasePerformance {
                VStack(spacing: 4) {
                    Text("Since Purchase")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Text(perf.percent, format: .percent.precision(.fractionLength(2)))
                            .font(.headline)
                            .foregroundColor(perf.percent >= 0 ? .green : .red)

                        Text(perf.dollars, format: .currency(code: currencyCode))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(perf.dollars >= 0 ? .green : .red)
                    }
                }
                .padding(.horizontal, 8)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Position Details (now ABOVE Impact + Trend)

    private var positionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position Details")
                .font(.headline)

            // Shares
            HStack {
                Text("Shares:")
                Spacer()
                Text(result.quantity, format: .number.precision(.fractionLength(3)))
                    .foregroundColor(.blue)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if editablePosition != nil {
                    showingEditSheet = true
                }
            }

            // Cost row (unit cost × qty = total)
            HStack {
                Text("Cost:")
                Spacer()

                let totalCost = result.costBasis
                let qty = result.quantity
                let unitCost = qty > 0 ? totalCost / qty : 0

                Text("\(unitCost.formatted(.currency(code: currencyCode))) × \(qty.formatted(.number.precision(.fractionLength(3)))) = \(totalCost.formatted(.currency(code: currencyCode)))")
                    .multilineTextAlignment(.trailing)
            }

            // Gain / Loss row
            HStack {
                Text("Gain / Loss:")
                Spacer()

                let totalCost = result.costBasis
                let currentValue = result.totalValue
                let gainLoss = currentValue - totalCost
                let gainLossPercent = totalCost > 0 ? gainLoss / totalCost : 0

                Text("\(gainLoss.formatted(.currency(code: currencyCode)))  (\(gainLossPercent.formatted(.percent.precision(.fractionLength(2)))))")
                    .foregroundColor(gainLoss >= 0 ? .green : .red)
                    .multilineTextAlignment(.trailing)
            }

            // Current Value
            HStack {
                Text("Current Value:")
                Spacer()
                Text(result.totalValue, format: .currency(code: currencyCode))
            }

            // 52WH
            HStack {
                Text("52WH:")
                Spacer()
                Text(result.yearHighPrice, format: .currency(code: currencyCode))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    // MARK: - 52WH Impact (now BELOW Position Details)

    private var impactSection: some View {
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
        }
        .padding(.horizontal)
    }

    // MARK: - Trend / Velocity (now BELOW Impact)

    private var trendSection: some View {
        Group {
            if !result.isCash {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trend / Velocity")
                        .font(.headline)

                    trendRow("5D:", slope: result.shortTermSlope)
                    trendRow("20D:", slope: result.mediumTermSlope)
                    trendRow("60D:", slope: result.longTermSlope)

                    HStack {
                        Text("Direction:")
                        Spacer()
                        Text(directionChangeLabel(result.directionChange))
                            .foregroundColor(directionColor(result.directionChange))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Helpers

    private var sincePurchasePerformance: (percent: Double, dollars: Double)? {
        guard range == .sincePurchase else { return nil }
        guard result.costBasis > 0 else { return nil }

        let cost = result.costBasis
        let current = result.currentPrice

        let percent = (current - cost) / cost
        let dollars = (current - cost) * result.quantity

        return (percent, dollars)
    }

    private func trendRow(_ label: String, slope: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(slopeText(slope))
                .foregroundColor(slopeColor(slope))
        }
    }

    private func slopeText(_ value: Double) -> String {
        value.formatted(.currency(code: currencyCode))
    }

    private func slopeColor(_ value: Double) -> Color {
        value < 0 ? .red : (value > 0 ? .green : .secondary)
    }

    private func directionChangeLabel(_ direction: TrendDirectionChange) -> String {
        switch direction {
        case .none: return "none"
        case .turningUp: return "turning up"
        case .turningDown: return "turning down"
        }
    }

    private func directionColor(_ direction: TrendDirectionChange) -> Color {
        switch direction {
        case .none: return .secondary
        case .turningUp: return .green
        case .turningDown: return .red
        }
    }

    // MARK: - Time Range Selector

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
    }

    // MARK: - Compact 52WH Summary

    private var compact52WHSummary: some View {
        VStack(alignment: .trailing, spacing: 4) {
            summaryItem(
                title: "52WH",
                value: String(format: "%.2f%%", result.percentDifferenceFromYearHigh),
                valueColor: result.percentDifferenceFromYearHigh < 0 ? .red : .green
            )

            summaryItem(
                title: "/sh",
                value: (highImpactPerShare).formatted(.currency(code: currencyCode)),
                valueColor: highImpactPerShare < 0 ? .red : .green
            )

            summaryItem(
                title: "Total",
                value: highImpactTotal.formatted(.currency(code: currencyCode)),
                valueColor: highImpactTotal < 0 ? .red : .green
            )
        }
        .padding(.top, 2)
    }

    private func summaryItem(title: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.caption2.weight(.semibold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
// End of StockDetailView.swift

