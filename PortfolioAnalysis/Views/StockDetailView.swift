//
//  StockDetailView.swift
//  PortfolioAnalysis
//

import SwiftUI
import Combine
import Foundation
import Charts

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
    private var selectedRange: TimeRange { range }
    @State private var showMA20 = false
    @State private var showMA200 = false
    @State private var showingEditSheet = false

    private var editablePosition: ImportedPosition? {
        viewModel.positions.first(where: { $0.symbol == result.symbol })
    }

    // MARK: - CLEANED DESCRIPTION
    private var cleanedDescription: String {
        let raw = holdingDescription

        let noBreaks = raw
            .replacingOccurrences(of: "\n", with: " - ")
            .replacingOccurrences(of: "\r", with: " - ")

        if noBreaks == noBreaks.uppercased() {
            return noBreaks
                .lowercased()
                .split(separator: " ")
                .map { $0.capitalized }
                .joined(separator: " ")
        }

        return noBreaks
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

    private var referenceHighColor: Color {
        result.currentPrice >= result.yearHighPrice ? .green : .secondary
    }

    private var dayChange: Double? {
        let sorted = history.sorted { $0.date < $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted.last!.close - sorted[sorted.count - 2].close
    }

    private var pageIndicatorText: String? {
        pageCount > 1 ? "\(pageIndex) of \(pageCount)" : nil
    }

    // MARK: - ⭐ sincePurchasePerformance MOVED HERE (before chartSection)

    private var sincePurchasePerformance: (percent: Double, dollars: Double)? {
        guard range == .sincePurchase else { return nil }
        guard result.costBasis > 0 else { return nil }

        let cost = result.costBasis
        let current = result.currentPrice

        let percent = (current - cost) / cost
        let dollars = (current - cost) * result.quantity

        return (percent, dollars)
    }

    // MARK: - BODY

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                headerSection
                timeRangeSelector
                chartSection

                positionDetailsSection
                impactSection      // polished
                trendSection       // polished
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

    // MARK: - HEADER (unchanged)

    private var headerSection: some View {
        VStack(spacing: 12) {

            Text(result.symbol)
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Text(cleanedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ClassificationBadgeView(classification: result.classification)
                .padding(.top, 4)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.currentPrice, format: .currency(code: currencyCode))
                        .font(.title2)

                    if let dayChange {
                        let prevClose = history.sorted { $0.date < $1.date }[max(0, history.count - 2)].close
                        let pct = prevClose != 0 ? dayChange / prevClose : 0
                        HStack(spacing: 6) {
                            Text("Day:")
                                .font(.caption)
                            Text(dayChange, format: .currency(code: currencyCode))
                                .font(.caption.weight(.semibold))
                            Text(pct, format: .percent.precision(.fractionLength(2)))
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
            .padding(.horizontal)

            if let pageIndicatorText {
                Text(pageIndicatorText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - CHART (unchanged except modified StockPriceChartView call)

    private var chartSection: some View {
        VStack(spacing: 8) {

            StockPriceChartView(
                history: history,
                range: selectedRange,
                showMA20: false,
                showMA200: false,
                referenceHigh: result.yearHighPrice,
                referenceHighColor: referenceHighColor,
                quantity: result.quantity,
                costBasis: result.costBasis,
                purchaseDate: editablePosition?.purchaseDate,
                unitCost: (result.quantity > 0 ? result.costBasis / result.quantity : 0)
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

    // MARK: - POSITION DETAILS (unchanged)

    private var positionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position Details")
                .font(.headline)

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

            HStack {
                Text("Cost:")
                Spacer()

                let totalCost = result.costBasis
                let qty = result.quantity
                let unitCost = qty > 0 ? totalCost / qty : 0

                Text("\(unitCost.formatted(.currency(code: currencyCode))) × \(qty.formatted(.number.precision(.fractionLength(3)))) = \(totalCost.formatted(.currency(code: currencyCode)))")
                    .multilineTextAlignment(.trailing)
            }

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
        .padding(.bottom, 10)
    }

    // MARK: - ⭐ POLISHED 52WH IMPACT

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("52‑Week High Impact")
                .font(.headline)
                .padding(.bottom, 4)

            VStack(spacing: 10) {

                impactRow(
                    label: "Per Share",
                    value: highImpactPerShare,
                    color: highImpactPerShare < 0 ? .red : .green
                )

                impactRow(
                    label: "Total Impact",
                    value: highImpactTotal,
                    color: highImpactTotal < 0 ? .red : .green
                )
            }
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func impactRow(label: String, value: Double, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Text(value.formatted(.currency(code: currencyCode)))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
        }
    }

    // MARK: - ⭐ POLISHED TREND / VELOCITY

    private var trendSection: some View {
        Group {
            if !result.isCash {
                VStack(alignment: .leading, spacing: 12) {

                    Text("Trend / Velocity")
                        .font(.headline)
                        .padding(.bottom, 4)

                    VStack(spacing: 10) {

                        polishedTrendRow(label: "5D", value: result.shortTermSlope)
                        polishedTrendRow(label: "20D", value: result.mediumTermSlope)
                        polishedTrendRow(label: "60D", value: result.longTermSlope)

                        Divider().padding(.vertical, 4)

                        HStack {
                            Text("Direction")
                                .font(.subheadline)
                            Spacer()
                            Text(directionChangeLabel(result.directionChange))
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(directionColor(result.directionChange))
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    private func polishedTrendRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            Text(slopeText(value))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(slopeColor(value))
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
        case .none: return "None"
        case .turningUp: return "Turning Up"
        case .turningDown: return "Turning Down"
        }
    }

    private func directionColor(_ direction: TrendDirectionChange) -> Color {
        switch direction {
        case .none: return .secondary
        case .turningUp: return .green
        case .turningDown: return .red
        }
    }

    // MARK: - TIME RANGE SELECTOR (unchanged)

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

    // MARK: - COMPACT 52WH SUMMARY (unchanged)

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

