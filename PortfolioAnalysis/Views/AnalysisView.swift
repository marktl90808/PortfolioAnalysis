import SwiftUI
import Charts

struct AnalysisView: View {
    @EnvironmentObject var portfolio: Portfolio
    @State private var sortOrder: SortOrder = .signal

    enum SortOrder: String, CaseIterable, Identifiable {
        case signal    = "By Signal"
        case gainLoss  = "By Gain/Loss"
        case value     = "By Value"
        var id: String { rawValue }
    }

    private var sortedHoldings: [Holding] {
        let base = portfolio.nonCashHoldings
        switch sortOrder {
        case .signal:
            let order: [AnalysisSignal] = [.considerExiting, .watchClosely, .considerSelling, .buyMore, .hold]
            return base.sorted {
                (order.firstIndex(of: $0.analysisSignal) ?? 99) <
                (order.firstIndex(of: $1.analysisSignal) ?? 99)
            }
        case .gainLoss:
            return base.sorted { $0.gainLossPercent < $1.gainLossPercent }
        case .value:
            return base.sorted { $0.marketValue > $1.marketValue }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if portfolio.holdings.isEmpty {
                    EmptyPortfolioView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            allocationSection
                            accountComparisonSection
                            holdingsAnalysisSection
                            optionsOpportunitiesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases) { o in
                                Text(o.rawValue).tag(o)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }

    // MARK: - Allocation

    private var allocationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Asset Allocation").font(.headline)

            HStack(alignment: .center, spacing: 20) {
                Chart(allocationData, id: \.label) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Type", item.label))
                    .cornerRadius(4)
                }
                .frame(width: 130, height: 130)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(allocationData, id: \.label) { item in
                        HStack(spacing: 6) {
                            Circle().frame(width: 8, height: 8)
                                .foregroundStyle(allocationColor(item.label))
                            Text(item.label).font(.caption)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(item.value, format: .currency(code: "USD").precision(.fractionLength(0)))
                                    .font(.caption.bold())
                                Text("\(Int(item.percent))%")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private struct AllocationItem {
        let label: String; let value: Double; let percent: Double
    }

    private var allocationData: [AllocationItem] {
        let total = portfolio.totalPortfolioValue
        guard total > 0 else { return [] }

        var byType: [String: Double] = [:]
        for h in portfolio.holdings {
            let key = h.assetType == .cash ? "Cash" : h.assetType.rawValue
            byType[key, default: 0] += h.marketValue
        }
        return byType.sorted { $0.key < $1.key }.map {
            AllocationItem(label: $0.key, value: $0.value, percent: ($0.value / total) * 100)
        }
    }

    private func allocationColor(_ label: String) -> Color {
        switch label {
        case "Stock":       return .blue
        case "ETF":         return .purple
        case "Mutual Fund": return .indigo
        case "Cash":        return .green
        default:            return .gray
        }
    }

    // MARK: - Account Comparison

    private var accountComparisonSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account Comparison").font(.headline)

            let accounts = portfolio.holdingsByAccount
            let maxVal = accounts.map { $0.value.reduce(0) { $0 + $1.marketValue } }.max() ?? 1

            ForEach(accounts, id: \.key) { (account, holdings) in
                let total  = holdings.reduce(0) { $0 + $1.marketValue }
                let gl     = holdings.filter { $0.assetType != .cash }.reduce(0) { $0 + $1.gainLoss }
                let glPct  = holdings.filter { $0.assetType != .cash }
                    .reduce(0) { $0 + $1.costBasis }
                let glPctVal = glPct > 0 ? (gl / glPct) * 100 : 0
                let type   = holdings.first?.accountType ?? .nonIRA

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(account).font(.subheadline.bold())
                            Text(type.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(total, format: .currency(code: "USD")).font(.subheadline)
                            Text("\(glPctVal >= 0 ? "+" : "")\(String(format: "%.1f", glPctVal))%")
                                .font(.caption.bold())
                                .foregroundStyle(glPctVal >= 0 ? .green : .red)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.systemGray5)).frame(height: 6)
                            Capsule()
                                .fill(type == .traditionalIRA ? Color.indigo : Color.blue)
                                .frame(width: geo.size.width * CGFloat(total / maxVal), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Holdings Analysis

    private var holdingsAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Holdings Analysis").font(.headline)

            ForEach(sortedHoldings) { holding in
                NavigationLink {
                    HoldingDetailView(holding: holding)
                } label: {
                    AnalysisHoldingRow(holding: holding)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Options Opportunities

    private var optionsOpportunitiesSection: some View {
        let candidates = portfolio.nonCashHoldings.filter { $0.isOptionable }
        guard !candidates.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Label("Options Income Opportunities", systemImage: "dollarsign.circle.fill")
                    .font(.headline)

                Text("Holdings suitable for options income strategies.")
                    .font(.caption).foregroundStyle(.secondary)

                ForEach(candidates.prefix(5)) { holding in
                    let strategies = OptionsStrategyEngine.strategies(for: holding)
                    if let top = strategies.first {
                        NavigationLink {
                            HoldingDetailView(holding: holding)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.12))
                                    Text(holding.symbol.prefix(4))
                                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                                        .foregroundStyle(.blue)
                                }
                                .frame(width: 48, height: 36)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(holding.symbol).font(.subheadline.bold())
                                    Text(top.name).font(.caption).foregroundStyle(.secondary)
                                }

                                Spacer()

                                if let income = top.estimatedMonthlyIncome {
                                    Text(income)
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// MARK: - Analysis Holding Row

struct AnalysisHoldingRow: View {
    let holding: Holding

    var body: some View {
        HStack(spacing: 12) {
            // Signal icon
            Image(systemName: holding.analysisSignal.systemImage)
                .font(.title3)
                .foregroundStyle(signalColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol).font(.subheadline.bold())
                Text(holding.analysisSignal.rawValue)
                    .font(.caption).foregroundStyle(signalColor)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.marketValue, format: .currency(code: "USD"))
                    .font(.subheadline)
                HStack(spacing: 2) {
                    Image(systemName: holding.gainLoss >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9))
                    Text("\(String(format: "%.2f", abs(holding.gainLossPercent)))%")
                        .font(.caption)
                }
                .foregroundStyle(holding.gainLoss >= 0 ? .green : .red)
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var signalColor: Color {
        switch holding.analysisSignal {
        case .considerSelling: return .green
        case .hold:            return .blue
        case .watchClosely:    return .orange
        case .considerExiting: return .red
        case .buyMore:         return .green
        }
    }
}
