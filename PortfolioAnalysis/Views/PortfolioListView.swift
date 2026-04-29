import SwiftUI

struct PortfolioListView: View {
    @EnvironmentObject var portfolio: Portfolio
    @StateObject private var marketData = MarketDataService.shared

    var body: some View {
        NavigationStack {
            Group {
                if portfolio.holdings.isEmpty {
                    EmptyPortfolioView()
                } else {
                    listContent
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await marketData.refreshAllPrices(portfolio: portfolio) }
                    } label: {
                        if marketData.isLoading {
                            ProgressView().controlSize(.small)
                        } else {
                            Label("Refresh Prices", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(portfolio.holdings.isEmpty || marketData.isLoading)
                }
            }
        }
    }

    private var listContent: some View {
        List {
            // Summary card
            Section {
                PortfolioSummaryCard()
            }

            // Accounts
            ForEach(portfolio.holdingsByAccount, id: \.key) { (account, holdings) in
                Section {
                    ForEach(holdings) { holding in
                        NavigationLink {
                            HoldingDetailView(holding: holding)
                        } label: {
                            HoldingRowView(holding: holding)
                        }
                    }
                } header: {
                    AccountHeaderView(accountName: account, holdings: holdings)
                }
            }

            // Last update timestamp
            if let date = portfolio.lastImportDate {
                Section {
                    Text("Imported \(date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Portfolio Summary Card

struct PortfolioSummaryCard: View {
    @EnvironmentObject var portfolio: Portfolio

    var body: some View {
        VStack(spacing: 14) {
            // Total value + gain/loss
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Portfolio Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(portfolio.totalPortfolioValue, format: .currency(code: "USD"))
                        .font(.title2.bold())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Gain / Loss")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: portfolio.totalGainLoss >= 0
                              ? "arrow.up.right" : "arrow.down.right")
                        Text(portfolio.totalGainLoss, format: .currency(code: "USD"))
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(portfolio.totalGainLoss >= 0 ? .green : .red)
                }
            }

            Divider()

            // Three-column stats
            HStack {
                SummaryStatView(title: "Cost Basis",
                                text: portfolio.totalCostBasis.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                color: .primary)
                Divider().frame(height: 32)
                SummaryStatView(title: "Return",
                                text: "\(portfolio.totalGainLossPercent >= 0 ? "+" : "")\(String(format: "%.2f", portfolio.totalGainLossPercent))%",
                                color: portfolio.totalGainLossPercent >= 0 ? .green : .red)
                Divider().frame(height: 32)
                SummaryStatView(title: "Cash",
                                text: portfolio.totalCashValue.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                color: .primary)
            }

            // IRA vs Non-IRA split
            HStack {
                let iraPct = portfolio.totalPortfolioValue > 0
                    ? portfolio.iraHoldings.reduce(0) { $0 + $1.marketValue } / portfolio.totalPortfolioValue
                    : 0
                SummaryStatView(title: "Non-IRA",
                                text: portfolio.nonIRAHoldings.reduce(0) { $0 + $1.marketValue }
                                    .formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                color: .blue)
                Divider().frame(height: 32)
                SummaryStatView(title: "Trad. IRA",
                                text: portfolio.iraHoldings.reduce(0) { $0 + $1.marketValue }
                                    .formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                color: .indigo)
                Divider().frame(height: 32)
                SummaryStatView(title: "IRA %",
                                text: "\(Int(iraPct * 100))%",
                                color: .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SummaryStatView: View {
    let title: String
    let text: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Account Header

struct AccountHeaderView: View {
    let accountName: String
    let holdings: [Holding]

    var totalValue: Double { holdings.reduce(0) { $0 + $1.marketValue } }
    var accountType: AccountType { holdings.first?.accountType ?? .nonIRA }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(accountName).font(.headline).foregroundStyle(.primary)
                Text(accountType.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(totalValue, format: .currency(code: "USD"))
                .font(.subheadline.bold())
        }
    }
}

// MARK: - Holding Row

struct HoldingRowView: View {
    let holding: Holding

    var body: some View {
        HStack(spacing: 12) {
            // Symbol badge
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(badgeColor.opacity(0.15))
                Text(holding.symbol.prefix(4))
                    .font(.system(.caption2, design: .monospaced, weight: .bold))
                    .foregroundStyle(badgeColor)
            }
            .frame(width: 52, height: 40)

            // Name / type
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.symbol).font(.subheadline.bold())
                Text(holding.name)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }

            Spacer()

            // Value / change
            VStack(alignment: .trailing, spacing: 2) {
                Text(holding.marketValue, format: .currency(code: "USD"))
                    .font(.subheadline)
                if holding.assetType != .cash {
                    HStack(spacing: 2) {
                        Image(systemName: holding.gainLoss >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9))
                        Text("\(String(format: "%.2f", abs(holding.gainLossPercent)))%")
                            .font(.caption)
                    }
                    .foregroundStyle(holding.gainLoss >= 0 ? .green : .red)
                } else {
                    Text("Cash").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var badgeColor: Color {
        switch holding.assetType {
        case .stock:      return .blue
        case .etf:        return .purple
        case .mutualFund: return .indigo
        case .cash:       return .green
        }
    }
}

// MARK: - Empty State

struct EmptyPortfolioView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Holdings", systemImage: "chart.pie")
        } description: {
            Text("Use the Import tab to paste your portfolio data.")
        }
    }
}
